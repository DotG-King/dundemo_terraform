output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value = aws_eip.jenkins_eip.public_ip
}