terraform {
  backend "s3" {
    bucket         = "lionpay-terraform-state"
    key            = "main/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "lionpay-terraform-locks"
  }
}
