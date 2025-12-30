variable "project_name" {
  type        = string
  description = "Project name for tagging"
  default     = "lionpay"
}

variable "central_region" {
  description = "Central region for ECR repositories"
  type        = string
  default     = "ap-northeast-2"
}

variable "repositories" {
  type        = list(string)
  description = "List of ECR repository names to create"
  default     = ["lionpay-auth", "lionpay-wallet"]
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default = {
    Team = "LionPay-Team1"
  }
}

