locals {
  instance_tags = {
    "Name"  = var.module_name
    "Role"  = var.instance_use
    Project = var.project_name
  }
}

resource "aws_instance" "smackdab" {
  key_name                    = var.keyname
  ami                         = var.ami
  instance_type               = var.type
  tags                        = local.instance_tags
  subnet_id                   = var.subnets
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = var.security_groups

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.root_volume_size
  }

  dynamic "ebs_block_device" {
    for_each = var.extra_ebs ? var.additional_volumes : {}
    content {
      device_name           = ebs_block_device.key
      volume_type           = ebs_block_device.value["volume_type"]
      volume_size           = ebs_block_device.value["volume_size"]
      encrypted             = ebs_block_device.value["encrypted"] != null ? ebs_block_device.value["encrypted"] : true
      delete_on_termination = ebs_block_device.value["delete_on_termination"] != null ? ebs_block_device.value["delete_on_termination"] : true
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
