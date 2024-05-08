terraform {

  backend "s3" {
    bucket  = "ankush-bucket-for-terraform"
    key     = "sample-project.tfstate"
    region  = "us-east-1"
    profile = "default"
  }
}

