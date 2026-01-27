# Module: app_back

## 1. 개요

이 Terraform 모듈은 dundemo 프로젝트의 스프링 부트 백엔드 애플리케이션을 실행하기 위한 컴퓨팅 리소스를 프로비저닝합니다.

주요 역할:
- 애플리케이션을 실행할 EC2 인스턴스 생성
- 인스턴스에 필요한 권한 부여
- Auto Scaling Group으로 인스턴스 관리

---

## 2. 생성되는 주요 리소스

- **`aws_instance`**: 백엔드 애플리케이션이 실행될 가상 서버(EC2 인스턴스)입니다.
- **`aws_iam_role` / `aws_iam_instance_profile`**: EC2 인스턴스가 다른 AWS 서비스(예: S3, SQS, RDS 등)에 안전하게 접근할 수 있도록 AWS 자격 증명을 코드에 하드코딩하지 않고 IAM 역할을 통해 권한을 부여합니다.
- **`aws_launch_template` / `aws_autoscaling_group`**: 트래픽 양에 따라 인스턴스 수를 자동으로 조절(Auto Scaling)하기 위해 사용될 수 있습니다. Launch Template은 인스턴스 시작에 필요한 구성을 정의합니다. 해당 프로젝트에서는 자동 배포를 위해서 ASG를 사용합니다.

---

## 3. 설계 고려사항

- **확장성**: `aws_autoscaling_group`을 사용하여 CPU 사용률과 같은 지표에 따라 인스턴스 수를 동적으로 늘리거나 줄여 비용 효율성과 안정성을 동시에 확보할 수 있습니다.
- **무중단 배포**: CI/CD 파이프라인과 연동하여 Blue/Green 또는 Rolling 업데이트 전략을 구현함으로써 배포 중에도 서비스 중단이 발생하지 않도록 구성할 수 있습니다.