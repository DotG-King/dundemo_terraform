data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"

  ingress {
    description = "Allow SSH access from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["218.49.231.116/32"]
  }

  ingress {
    description = "Allow Jenkins web access from home"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["218.49.231.116/32"]
  }

  ingress {
    description = "Allow Github webhooks to Jenkins"
    from_port = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.jenkins_key_pair.key_name
  security_groups = [aws_security_group.jenkins_sg.name]
  availability_zone = "ap-northeast-2a"

  user_data = <<-EOF
              #!/bin/bash
              # 1. 시스템 업데이트 & Java 설치
              sudo dnf update -y
              sudo dnf install -y java-17-amazon-corretto-devel

              # 2. EBS 준비 (attach 대기 → 포맷 → 마운트)
              # (여기서 포맷은 최초 1회만, 기존 볼륨이면 건너뜀)
              EBS_DEVICE="/dev/sdf"
              ALT_DEVICE="/dev/xvdf"
              JENKINS_HOME="/var/lib/jenkins"

              # EBS 볼륨이 연결될 때까지 최대 1분 대기
              echo "Waiting for EBS volume to be attached..."
              for i in {1..60}; do
                if [ -e "$EBS_DEVICE" ]; then
                  echo "EBS volume found at $EBS_DEVICE."
                  break
                fi
                sleep 1
              done

              if [ ! -e "$EBS_DEVICE" ]; then
                echo "EBS volume not found after 60 seconds. Exiting." >&2
                exit 1
              fi

              # Jenkins 홈 디렉터리 생성
              sudo mkdir -p $JENKINS_HOME

              # 파일 시스템 확인 및 생성 (볼륨이 비어있는 경우)
              FS_TYPE=$(sudo blkid -s TYPE -o value $EBS_DEVICE || sudo blkid -s TYPE -o value $ALT_DEVICE || true)
              if [ -z "$FS_TYPE" ]; then
                echo "No filesystem detected on $EBS_DEVICE → check volume size"

                # 볼륨 크기 확인 → 0바이트면 신규 볼륨으로 간주
                VOL_SIZE=$(sudo blockdev --getsize64 $EBS_DEVICE)
                if [ "$VOL_SIZE" -gt 0 ]; then
                  echo "Formatting volume as xfx..."
                  sudo mkfs -t xfs $EBS_DEVICE
                else
                  echo "Volume seems invalid, skipping format."
                  exit 1
                fi
              else
                echo "Existing filesystem ($FS_TYPE) found → skipping format"
              fi

              # /etc/fstab에 항목이 이미 있는지 확인하여 중복 추가 방지
              UUID=$(sudo blkid -s UUID -o value $EBS_DEVICE || sudo blkid -s UUID -o value $ALT_DEVICE)
              if ! grep -q "UUID=$UUID" /etc/fstab; then
                echo "Adding EBS volume to /etc/fstab..."
                echo "UUID=$UUID $JENKINS_HOME xfs defaults,nofail,x-systemd.device-timeout=30 0 2" | sudo tee -a /etc/fstab
              fi

              # 볼륨 마운트
              sudo mount -a

              # 마운트 성공 확인
              if ! mountpoint -q $JENKINS_HOME; then
                  echo "Failed to mount $JENKINS_HOME. Exiting." >&2
                  exit 1
              fi

              # 3. 소유권 맞추기
              sudo chown -R jenkins:jenkins $JENKINS_HOME

              # 4. Jenkins 리포지토리 추가 & 설치
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo dnf install -y jenkins

              # 5. Jenkins 서비스 시작
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              echo "Jenkins setup complete."
              EOF

  tags = {
    Name = "jenkins-server"
  }
}

# 젠킨스 데이터를 저장할 EBS 볼륨 생성
resource "aws_ebs_volume" "jenkins_data" {
  availability_zone = "ap-northeast-2a"
  size = 5
  type = "gp3"

  tags = {
    Name = "jenkins-data-volume"
  }
}

# 생성한 EBS 볼륨을 젠킨스 서버 인스턴스에 장착
resource "aws_volume_attachment" "jenkins_data_attachment" {
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.jenkins_data.id
  instance_id = aws_instance.jenkins_server.id
}

# 고정 IP 생성
resource "aws_eip" "jenkins_eip" {
  tags = {
    Name = "jenkins_eip"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.jenkins_server.id
  allocation_id = aws_eip.jenkins_eip.id
}
