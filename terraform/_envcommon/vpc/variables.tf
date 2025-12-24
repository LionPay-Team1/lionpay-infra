variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region_seoul" {
  type    = string
  default = "ap-northeast-2"
}

variable "region_tokyo" {
  type    = string
  default = "ap-northeast-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Seoul VPC
variable "seoul_vpc_cidr" {
  type = string
}

variable "seoul_azs" {
  type = list(string)
}

variable "seoul_private_subnet_cidrs" {
  type = list(string)
}

variable "seoul_public_subnet_cidrs" {
  type = list(string)
}

variable "seoul_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "seoul_single_nat_gateway" {
  type    = bool
  default = true
}

# Tokyo VPC
variable "tokyo_vpc_cidr" {
  type = string
}

variable "tokyo_azs" {
  type = list(string)
}

variable "tokyo_private_subnet_cidrs" {
  type = list(string)
}

variable "tokyo_public_subnet_cidrs" {
  type = list(string)
}

variable "tokyo_enable_nat_gateway" {
  type    = bool
  default = true
}

variable "tokyo_single_nat_gateway" {
  type    = bool
  default = true
}
