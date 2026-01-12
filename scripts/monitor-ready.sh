#!/usr/bin/env bash
set -euo pipefail

INTERVAL_SEC=${INTERVAL_SEC:-30}
MAX_MIN=${MAX_MIN:-30}
MAX_SEC=$((MAX_MIN*60))
START_TS=$(date +%s)

ZONE_NAME=${ZONE_NAME:-lionpay.shop}
RECORD_NAME=${RECORD_NAME:-origin-api.lionpay.shop.}

SEOUL_CTX=${SEOUL_CTX:-lionpay-dev-seoul}
TOKYO_CTX=${TOKYO_CTX:-lionpay-dev-tokyo}
SEOUL_REGION=${SEOUL_REGION:-ap-northeast-2}
TOKYO_REGION=${TOKYO_REGION:-ap-northeast-1}

aws eks update-kubeconfig --name lionpay-dev-seoul --region "$SEOUL_REGION" --alias "$SEOUL_CTX" --no-cli-pager >/dev/null
aws eks update-kubeconfig --name lionpay-dev-tokyo --region "$TOKYO_REGION" --alias "$TOKYO_CTX" --no-cli-pager >/dev/null

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$ZONE_NAME" --query "HostedZones[0].Id" --output text --no-cli-pager | sed 's|/hostedzone/||')

now() { date '+%F %T'; }

get_ingress_alb() {
  local ctx="$1"
  kubectl --context "$ctx" -n lionpay get ingress lionpay-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true
}

alb_active() {
  local region="$1" dns="$2"
  aws elbv2 describe-load-balancers --region "$region" \
    --query "LoadBalancers[?DNSName=='$dns'].State.Code | [0]" \
    --output text --no-cli-pager 2>/dev/null | grep -qi '^active$'
}

route53_alias_for() {
  local region="$1" identifier="$2"
  aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query "ResourceRecordSets[?Name=='$RECORD_NAME' && SetIdentifier=='$identifier'].AliasTarget.DNSName | [0]" \
    --output text --no-cli-pager 2>/dev/null || true
}

argocd_ok() {
  # ArgoCD capability CRDs live in Seoul cluster
  local s_sync s_health t_sync t_health

  s_sync=$(kubectl --context "$SEOUL_CTX" -n argocd get applications.argoproj.io lionpay-dev-seoul -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  s_health=$(kubectl --context "$SEOUL_CTX" -n argocd get applications.argoproj.io lionpay-dev-seoul -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  t_sync=$(kubectl --context "$SEOUL_CTX" -n argocd get applications.argoproj.io lionpay-dev-tokyo -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  t_health=$(kubectl --context "$SEOUL_CTX" -n argocd get applications.argoproj.io lionpay-dev-tokyo -o jsonpath='{.status.health.status}' 2>/dev/null || true)

  [[ "$s_sync" == "Synced" && "$s_health" == "Healthy" && "$t_sync" == "Synced" && "$t_health" == "Healthy" ]]
}

while true; do
  ELAPSED=$(( $(date +%s) - START_TS ))
  if [ "$ELAPSED" -gt "$MAX_SEC" ]; then
    echo "[$(now)] TIMEOUT after ${MAX_MIN}m" >&2
    exit 1
  fi

  SEOUL_ALB=$(get_ingress_alb "$SEOUL_CTX")
  TOKYO_ALB=$(get_ingress_alb "$TOKYO_CTX")

  SEOUL_EXPECTED="dualstack.${SEOUL_ALB}."
  TOKYO_EXPECTED="dualstack.${TOKYO_ALB}."

  R53_SEOUL=$(route53_alias_for "$SEOUL_REGION" "lionpay-latency-seoul")
  R53_TOKYO=$(route53_alias_for "$TOKYO_REGION" "lionpay-latency-tokyo")

  OK_SEOUL_INGRESS=0; [[ -n "$SEOUL_ALB" ]] && OK_SEOUL_INGRESS=1
  OK_TOKYO_INGRESS=0; [[ -n "$TOKYO_ALB" ]] && OK_TOKYO_INGRESS=1

  OK_SEOUL_ALB=0; if [[ -n "$SEOUL_ALB" ]] && alb_active "$SEOUL_REGION" "$SEOUL_ALB"; then OK_SEOUL_ALB=1; fi
  OK_TOKYO_ALB=0; if [[ -n "$TOKYO_ALB" ]] && alb_active "$TOKYO_REGION" "$TOKYO_ALB"; then OK_TOKYO_ALB=1; fi

  OK_R53=0
  if [[ -n "$SEOUL_ALB" && -n "$TOKYO_ALB" && "$R53_SEOUL" == "$SEOUL_EXPECTED" && "$R53_TOKYO" == "$TOKYO_EXPECTED" ]]; then
    OK_R53=1
  fi

  OK_ARGOCD=0
  if argocd_ok; then OK_ARGOCD=1; fi

  echo "[$(now)] seoul_ingress=$OK_SEOUL_INGRESS seoul_alb_active=$OK_SEOUL_ALB tokyo_ingress=$OK_TOKYO_INGRESS tokyo_alb_active=$OK_TOKYO_ALB route53_match=$OK_R53 argocd=$OK_ARGOCD"
  echo "         seoul_alb=$SEOUL_ALB"
  echo "         tokyo_alb=$TOKYO_ALB"
  echo "         r53_seoul=$R53_SEOUL"
  echo "         r53_tokyo=$R53_TOKYO"

  if [ "$OK_SEOUL_INGRESS" = 1 ] && [ "$OK_TOKYO_INGRESS" = 1 ] && \
     [ "$OK_SEOUL_ALB" = 1 ] && [ "$OK_TOKYO_ALB" = 1 ] && \
     [ "$OK_R53" = 1 ] && [ "$OK_ARGOCD" = 1 ]; then
    echo "[$(now)] ALL OK"
    exit 0
  fi

  sleep "$INTERVAL_SEC"
done
