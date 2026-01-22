provider "aws" {
  region                   = "ap-northeast-2"
  profile                  = "default"
  shared_credentials_files = ["../.aws/credentials"]
}

provider "aws" {
  alias                    = "us_east_1"
  region                   = "us-east-1"
  profile                  = "default"
  shared_credentials_files = ["../.aws/credentials"]
}
