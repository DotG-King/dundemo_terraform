resource "aws_security_group" "load_balancer_sg" {
  name = "load_balancer_sg"
  description = "Security group for application load balancer"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "Allow HTTP access from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS access from anywhere"
    from_port = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_application_load_balancer_sg"
  }
}

resource "aws_security_group" "eic_endpoint_sg" {
  name = "eic_endpoint_sg"
  description = "Security group for EC2 Instance Connect endpoint"
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_eic_endpoint_sg"
  }
}

resource "aws_security_group" "backend_sg" {
  name = "backend_sg"
  description = "Security group for backend server"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH via EC2 Instance Connect Endpoint"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.eic_endpoint_sg.id]
  }

  ingress {
    description = "Allow application access from Load Balancer"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_backend_security_group"
  }
}

resource "aws_security_group" "database_sg" {
  name        = "database_sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH via EC2 Instance Connect Endpoint"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.eic_endpoint_sg.id]
  }

  ingress {
    description = "Allow MongoDB access from Backend server"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_database_security_group"
  }
}
