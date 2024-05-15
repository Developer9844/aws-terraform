resource "aws_instance" "ec2_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  availability_zone           = var.availability_zone[0]
  key_name                    = var.key_name
  subnet_id                   = var.subnet_ids[0]
  security_groups             = [var.sg_id] # we [] this for avoid "string" error
}

