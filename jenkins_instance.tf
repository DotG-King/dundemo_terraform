resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["218.49.231.116/32"] # WARNING: This allows SSH from anywhere. For production, restrict this to your IP.
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["218.49.231.116/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-077ad873396d76f6a" # Amazon Linux 2023 AMI for us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.jenkins_key_pair.key_name # <-- IMPORTANT: Replace with your EC2 key pair name
  security_groups = [aws_security_group.jenkins_sg.name]

  user_data = <<-EOF
              # !/bin/bash
              # 시스템 패키지 업데이트
              sudo dnf update -y

              # JAVA 17 설치 (Jenkins 최신 버전에 권장)
              sudo dnf install -y java-17-amazon-corretto-devel

              # Jenkins 리포지토리 추가
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              
              # Jenkins 설치
              sudo dnf install -y jenkins
              
              # Jenkins 서비스 시작 및 활성화
              
              sudo systemctl daemon-reload
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF

  tags = {
    Name = "jenkins-server"
  }
}
