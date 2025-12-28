provider "aws" {
  region = var.region_seoul
}

provider "aws" {
  alias  = "tokyo"
  region = var.region_tokyo
}
