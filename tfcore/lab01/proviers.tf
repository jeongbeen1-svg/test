resource "aws_security_group" "my_sg" {
  name        = "tf-core-lab01-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id # main.tf에 있는 vpc 모듈을 참조

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
