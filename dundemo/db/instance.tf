resource "aws_instance" "db_server" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.database_sg_id]
  associate_public_ip_address = false
  availability_zone           = "ap-northeast-2a"

  user_data = <<-EOF
              #!/bin/bash
              set -e  
              # 1. MongoDB 설치
              cat << 'REPO_EOF' > /etc/yum.repos.d/mongodb-org-7.0.repo
              [mongodb-org-7.0]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
              REPO_EOF

              dnf clean all
              dnf install -y mongodb-org

              # /etc/mongod.conf 파일을 수정하여 외부 연결을 허용합니다.
              echo "Updating mongod.conf to bind to 0.0.0.0"
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

              # 2. EBS 볼륨 포맷 및 마운트
              # (포맷은 최초 1회만, 기존 불륨이면 건너뜀)
              EBS_DEVICE="/dev/sdf"
              ALT_DEVICE="/dev/xvdf"
              MOUNT_POINT="/var/lib/mongodb"

              echo "Waiting for EBS volume to be attached..."
              for i in {1..60}; do
                if [ -e "$EBS_DEVICE" ]; then
                  echo "EBS volume found at $EBS_DEVICE."
                  break
                fi
                sleep 1
              done

              if [ ! -e "$EBS_DEVICE" ]; then
                echo "EBS volume not found. Exiting." >&2
                exit 1
              fi

              # 마운트 포인트 디렉토리 생성
              sudo mkdir -p $MOUNT_POINT

              # 파일 시스템 확인 및 생성 (볼륨이 비어있는 경우)
              FS_TYPE=$(sudo blkid -s TYPE -o value $EBS_DEVICE || sudo blkid -s TYPE -o value $ALT_DEVICE || true)
              if [ -z "$FS_TYPE" ]; then
                echo "No filesystem detected on $EBS_DEVICE → check volume size"

                VOL_SIZE=$(sudo blockdev --getsize64 $EBS_DEVICE)
                if [ "$VOL_SIZE" -gt 0 ]; then
                  echo "Formatting volume as xfs..."
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
              if ! grep -q "$UUID" /etc/fstab; then
                echo "Adding EBS volume to /etc/fstab..."
                echo "UUID=$UUID $MOUNT_POINT xfs defaults,nofail,x-systemd.device-timeout=30 0 2" | sudo tee -a /etc/fstab
              fi

              # 볼륨 마운트
              sudo mount -a

              # 마운트 성공 확인
              if ! mountpoint -q $MOUNT_POINT; then
                echo "Failed to mount $MOUNT_POINT. Exiting." >&2
                exit 1
              fi

              # 3. 소유권 맞추기
              sudo chown -R mongod:mongod $MOUNT_POINT

              # 4. MongoDB 서비스 시작 및 활성화
              systemctl enable mongod
              systemctl start mongod

              echo "MongoDB setup complete."
              EOF

  tags = {
    Name = "dundemo_${terraform.workspace}_db_server"
  }
}

resource "aws_ebs_volume" "db_data_volume" {
  availability_zone = "ap-northeast-2a"
  size              = 5
  type              = "gp3"

  tags = {
    Name = "dundemo_${terraform.workspace}_db_data_volume"
  }
}

resource "aws_volume_attachment" "db_data_volume_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.db_data_volume.id
  instance_id = aws_instance.db_server.id
}
