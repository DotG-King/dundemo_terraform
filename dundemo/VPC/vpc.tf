# VPC 생성
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dundemo_${terraform.workspace}_vpc"
  }
}

# Public Subnet 생성
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dundemo_${terraform.workspace}_public_subnet"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "dundemo_${terraform.workspace}_public_subnet_b"
  }
}

# Private Subnet 생성
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "dundemo_${terraform.workspace}_private_subnet"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "dundemo_${terraform.workspace}_private_subnet_b"
  }
}

# Internet Gateway 생성 및 VPC에 연결
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dundemo_${terraform.workspace}_internet_gateway"
  }
}

# Public Subnet을 위한 라우팅 테이블 생성
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                              # 인터넷으로 가는 모든 트래픽
    gateway_id = aws_internet_gateway.internet_gateway.id # Internet Gateway를 통해 라우팅
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_public_route_table"
  }
}

# Public Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway를 위한 탄력적 IP 생성
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "dundemo_${terraform.workspace}_nat_eip"
  }
}

# NAT 게이트웨이 생성
# NAT Gateway는 Public Subnet에 생성되어야 합니다.
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "dundemo_${terraform.workspace}_nat_gateway"
  }

  # NAT Gateway는 Internet Gateway가 생성된 후에 생성되어야 합니다.
  depends_on = [aws_internet_gateway.internet_gateway]
}

# Private Subnet을 위한 라우팅 테이블 생성
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  # 인터넷으로 나가는 모든 트래픽을 NAT 게이트웨이로 보냄
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_private_route_table"
  }
}

# Private Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_b_association" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_route_table.id
}
