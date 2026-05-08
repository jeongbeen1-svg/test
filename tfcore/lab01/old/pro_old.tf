terraform {
  required_version = ">=1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"

}

resource "aws_security_group" "my_sg" {
   name = "tf-core-lab01-sg"

   vpc_id = module.vpc.vpc_id
}
