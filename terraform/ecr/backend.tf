terraform {
  backend "s3" {
    bucket         = "lionpay-terraform-state"
    key            = "ecr/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "lionpay-terraform-locks"
  }
}
