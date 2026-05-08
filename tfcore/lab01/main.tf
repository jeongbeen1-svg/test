# 1. 테라폼 및 프로바이더 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전
}

# 2. VPC 모듈 호출 (네트워크 추상화)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "kdt-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false # 테스트용이므로 NAT 생략 (비용 절감)
  tags = {
    Environment = "dev"
  }
}

# 3. 보안 그룹 생성 (SSH 접속용)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["58.72.80.3/32"] # 실무에서는 본인 IP만 허용 권장
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. EC2 인스턴스 생성
resource "aws_instance" "kdt_ec2" {
  ami           = "ami-0c9c942bd7bf113a2" # Ubuntu 22.04 LTS (서울 리전)
  instance_type = "t3.small"               # 요청하신 사양
  associate_public_ip_address = true       # 퍼블릭 IP를 강제로 할당받도록 설정

  # VPC 모듈에서 생성된 서브넷 ID와 보안 그룹 ID 연결
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "KDT-Standard-EC2"
  }
}