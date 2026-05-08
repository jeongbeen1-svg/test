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

# 2. VPC 모듈 호출 (중복되지 않도록 CIDR 대역 변경)
module "vpc_new" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "kdt-vpc-secondary"
  cidr = "10.1.0.0/16" # 기존 10.0.0.0/16과 겹치지 않게 변경

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"] # 서브넷 대역도 10.1.x.x로 변경

  enable_nat_gateway = false # 테스트용 비용 절감
  
  tags = {
    Environment = "dev-secondary"
  }
}

# 3. 보안 그룹 생성 (SSH 접속용)
resource "aws_security_group" "allow_ssh_new" {
  name        = "allow_ssh_secondary"
  description = "Allow SSH inbound traffic for secondary VPC"
  vpc_id      = module.vpc_new.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["58.72.80.3/32"] # 본인 IP 허용 설정 유지
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. EC2 인스턴스 생성 (태그 이름 변경 및 퍼블릭 IP 설정 적용)
resource "aws_instance" "kdt_ec2_new" {
  ami           = "ami-0c9c942bd7bf113a2" # Ubuntu 22.04 LTS
  instance_type = "t3.small"
  
  # 퍼블릭 IP 할당 옵션 명시
  associate_public_ip_address = true 

  # 위에서 새로 정의한 vpc_new의 서브넷과 보안 그룹 연결
  subnet_id              = module.vpc_new.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh_new.id]

  tags = {
    Name = "KDT-Secondary-EC2" # 인스턴스 태그 이름 변경
  }
}
