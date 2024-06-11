# create security group for the application load balancer

resource "aws_security_group" "smackdab_security_group" {
  name        = "${var.module_name}_security_group"
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_access
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_access
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name    = "${var.module_name}-ssh-security-group"
    Project = var.project_name
    Role    = var.module_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
