region        = "us-east-1"
region_name   = "virginia"
project_name  = "sample-project-terraform"
key_name      = "my_key"
ami           = "ami-0e001c9271cf7f3b9"
instance_type = "t2.micro"
cluster_name  = "eks"
aws_profile   = "my_personal_aws"

ingress_rules = {
  http = {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }
  ssh_my_ip = {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.215.158.90/32"]
    description = "Allow SSH traffic from my IP"
  }
  ftp_my_ip = {
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["103.215.158.90/32"]
    description = "Allow FTP traffic from my IP"
  }
  https = {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow HTTPS traffic from 10.0.0.0/16"
  }
}

