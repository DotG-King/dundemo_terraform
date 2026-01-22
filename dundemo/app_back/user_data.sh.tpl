#!/bin/bash
# 패키지 목록 업데이트 및 Java 17 (Amazon Corretto) 설치
echo "Starting application deployment script..."
echo "Updating packages and installing Java 17..."
sudo dnf update -y
sudo dnf install java-17-amazon-corretto -y

# AWS CLI 설치 (기본 AMI에 없을 경우)
echo "Installing AWS CLI..."
sudo dnf install awscli -y

# SSM Parameter Store에서 MONGO_URI 가져오기
echo "Getting MONGO_URI from SSM Parameter Store..."
MONGO_URI=$(aws ssm get-parameter --name "/app/${workspace}/mongo/uri" --with-decryption --region ap-northeast-2 --query "Parameter.Value" --output text)
echo "Detected MONGO_URI: $${MONGO_URI}"

# SSM Parameter Store에서 API_KEY 가져오기
echo "Getting API_KEY from SSM Parameter Store..."
API_KEY=$(aws ssm get-parameter --name "/app/api/key" --with-decryption --region ap-northeast-2 --query "Parameter.Value" --output text)
echo "Detected API_KEY: $${API_KEY}"

# SSM Parameter Store에서 애플리케이션 버전 ID 가져오기
echo "Getting application version number from SSM Parameter Store..."
APP_VERSION_NUMBER=$(aws ssm get-parameter --name "/app/${workspace}/version_number" --region ap-northeast-2 --query "Parameter.Value" --output text)
echo "Detected APP_VERSION_NUMBER: $${APP_VERSION_NUMBER}"

# S3 버킷 이름 가져오기
echo "Setting S3 bucket name..."
S3_BUCKET_NAME="${s3_bucket_name}"

# JAR 파일 이름 구성
echo "Constructing JAR file name..."
JAR_NAME="dundemo-v$${APP_VERSION_NUMBER}.jar"
S3_URI="s3://${s3_bucket_name}/$${JAR_NAME}"
LOCAL_JAR_PATH="/opt/app/$${JAR_NAME}"
APP_HOME="/opt/app"
echo "JAR_NAME: $${JAR_NAME}"

# 애플리케이션 디렉토리 생성 및 권한 설정
echo "Creating application directory..."
sudo mkdir -p $${APP_HOME}
sudo chown -R ec2-user:ec2-user $${APP_HOME}

# S3에서 JAR 파일 다운로드
echo "Downloading application JAR from S3..."
aws s3 cp $${S3_URI} $${LOCAL_JAR_PATH}

# Systemd 서비스 파일 생성
echo "Creating systemd service file..."
cat > /etc/systemd/system/dundemo-app.service <<SERVICE_EOF
[Unit]
Description=Dundemo Spring Boot Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$${APP_HOME}
Environment="SPRING_PROFILES_ACTIVE=${workspace}"
Environment="MONGO_URI=$${MONGO_URI}"
Environment="API_KEY=$${API_KEY}"
ExecStart=/usr/bin/java -jar $${LOCAL_JAR_PATH}
SuccessExitStatus=143
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 서비스 활성화 및 시작
echo "Enabling and starting dundemo-app service..."
sudo systemctl daemon-reload
sudo systemctl enable dundemo-app.service
sudo systemctl start dundemo-app.service

echo "Application deployment script finished."