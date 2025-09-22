provider "aws" {
  region = "ap-northeast-2"
  profile = "default"
  shared_credentials_files = ["${path.module}/.aws/credentials"]
}
