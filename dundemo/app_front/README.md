# Module: Frontend Infrastructure

## 1. 개요

이 Terraform 모듈은 Dundemo 프로젝트의 프론트엔드 애플리케이션(React, Vue 등)을 사용자에게 제공하기 위한 인프라를 정의합니다.

주요 역할은 다음과 같습니다.
1.  빌드된 정적 파일(HTML, CSS, JS)을 S3 버킷에 저장합니다.
2.  AWS CloudFront(CDN)를 통해 사용자에게 콘텐츠를 빠르고 안전하게 전송합니다.
3.  HTTPS 통신을 위한 SSL 인증서를 적용합니다.

---

## 2. 생성되는 주요 리소스

- **`aws_s3_bucket`**: 프론트엔드 애플리케이션의 빌드 결과물(정적 파일)을 호스팅하기 위한 S3 버킷입니다.
- **`aws_s3_bucket_policy`**: S3 버킷에 CloudFront만 접근할 수 있도록 제한하는 정책을 설정합니다.
- **`aws_cloudfront_distribution`**: 전 세계에 분산된 엣지 로케이션에 콘텐츠를 캐싱하여 사용자에게 낮은 지연 시간으로 콘텐츠를 제공하는 CDN 배포입니다.
- **`aws_cloudfront_origin_access_control` (OAC)**: 사용자가 S3 URL을 통해 직접 파일에 접근하는 것을 방지하고, CloudFront를 통해 S3 버킷에 안전하게 접근하도록 허용하는 최신 보안 설정입니다. OAI를 대체하는 기능으로, 더 세분화된 접근 제어를 제공합니다.
- **`aws_acm_certificate`**: CloudFront에 연결할 커스텀 도메인에 HTTPS를 적용하기 위한 SSL 인증서입니다. (Route53에서 발급 및 검증)

---

## 3. 배포 흐름

1.  CI/CD 파이프라인에서 프론트엔드 프로젝트를 빌드하고 정적 파일들을 S3 버킷에 업로드합니다.
2.  사용자가 도메인(예: `www.dundemo.in`)에 접속하면, CloudFront가 S3 버킷에서 콘텐츠를 가져와 사용자에게 전송합니다.
3.  이때, OAC 설정으로 인해 S3 버킷은 CloudFront의 요청에만 응답하므로 보안이 강화됩니다.
