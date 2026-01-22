resource "aws_ec2_instance_connect_endpoint" "eic_endpoint" {
  subnet_id = aws_subnet.private.id
  security_group_ids = [aws_security_group.eic_endpoint_sg.id]

  tags = {
    Name = "dundemo_${terraform.workspace}_eic_endpoint"
  }
}