resource "aws_key_pair" "jenkins_key_pair" {
  key_name = "jenkins_key_pair"
  public_key = file("~/.ssh/jenkins_key_pair.pub")
}