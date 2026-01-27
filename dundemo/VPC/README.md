# Module: VPC

## 1. 개요

이 모듈은 dundemo 애플리케이션의 모든 리소스가 배포될 격리되고 안전한 네트워크 환경을 생성합니다. AWS의 VPC(Virtual Private Cloud)를 기반으로 하며, 애플리케이션의 기반이 되는 가장 중요한 부분입니다.

---

## 2. 생성되는 주요 리소스

- **`aws_vpc`**: 프로젝트를 위한 논리적으로 격리된 가상 네트워크입니다.
- **`aws_subnet`**:
  - **Public Subnets**: 외부 인터넷과 직접 통신할 수 있는 서브넷으로, Application Load Balancer가 위치합니다.
  - **Private Subnets**: 외부에서 직접 접근할 수 없는 내부 서브넷으로, EC2 인스턴스나 RDS 데이터베이스와 같은 주요 리소스를 안전하게 배치합니다.
- **`aws_internet_gateway`**: VPC가 외부 인터넷과 통신할 수 있도록 하는 게이트웨이입니다.
- **`aws_nat_gateway`**: Private Subnet에 있는 리소스가 외부 인터넷으로 나가는(Outbound) 통신을 할 수 있도록 하지만, 외부에서는 들어올 수 없도록(Inbound) 하는 역할을 합니다. (예: 외부 API 호출, OS 업데이트)
- **`aws_route_table`**: 서브넷의 네트워크 트래픽이 어디로 가야 할지를 결정하는 라우팅 규칙 테이블입니다. Public/Private 서브넷에 따라 다르게 구성됩니다.
- **`aws_security_group`**: 리소스 수준의 방화벽 역할을 하며, 인스턴스로 들어오고 나가는 트래픽을 제어합니다.

---

## 3. 구조 설명

- **고가용성 확보**: 2개 이상의 가용 영역(Availability Zone)에 Public/Private 서브넷을 각각 생성하여 일부 AZ에 장애가 발생하더라도 서비스가 중단되지 않도록 설계합니다.
- **보안 강화**: 중요한 리소스(WAS, DB)는 Private Subnet에 배치하여 외부의 직접적인 접근을 차단하고, 필요한 통신만 Security Group과 Load Balancer를 통해 허용합니다.
