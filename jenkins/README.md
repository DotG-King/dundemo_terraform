# Module: Jenkins CI/CD Infrastructure

## 1. 개요

이 Terraform 모듈은 프로젝트의 CI/CD(지속적 통합/지속적 배포)를 담당하는 Jenkins 서버를 구성하기 위한 인프라를 정의합니다.

주요 역할:
- 소스 코드 빌드, 테스트, 배포 자동화를 위한 Jenkins 마스터 노드 생성
- 외부 접근 및 보안을 위한 네트워크 설정

---

## 2. 생성되는 주요 리소스

- **`aws_instance`**: Jenkins 서버로 사용될 EC2 인스턴스
- **`aws_security_group`**: Jenkins 대시보드(8080) 및 SSH(22) 접근을 제어하는 보안 그룹
- **`aws_iam_role` / `aws_iam_instance_profile`**: EC2 인스턴스가 다른 AWS 서비스(예: S3, ECR)에 접근할 수 있도록 권한을 부여하는 IAM 역할
- **`aws_key_pair`**: EC2 인스턴스에 SSH로 접근하기 위한 키 페어

---
