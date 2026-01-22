resource "aws_key_pair" "dundemo_key_pair" {
  key_name   = "dundemo_${terraform.workspace}_key_pair"
  public_key = file("~/.ssh/dundemo_key_pair.pub")
}
