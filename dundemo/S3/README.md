# Module: S3

## 1. 개요

이 Terraform 모듈은 dundemo 프로젝트에서 사용될 AWS S3(Simple Storage Service) 버킷을 생성하고 관리합니다.

---

## 2. 생성되는 주요 리소스

- **`aws_s3_bucket`**: 데이터를 저장할 S3 버킷을 생성합니다.
- **`aws_s3_bucket_policy`**: 버킷에 대한 접근 권한을 제어하는 정책을 정의합니다.
- **`aws_s3_bucket_public_access_block`**: 버킷에 대한 퍼블릭 접근을 차단하여 의도치 않은 데이터 노출을 방지합니다.
- **`aws_s3_bucket_versioning`**: 객체의 모든 버전을 보존하여 실수로 인한 삭제나 덮어쓰기로부터 데이터를 보호합니다.

---

## 3. 사용 목적에 따른 구성

- **backend app artifacts**: ci/cd 파이프라인에서 백엔드 프로젝트를 빌드하여 생성된 JAR파일을 보관합니다.
