# we use this output to export our variable

output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = aws_vpc.my-vpc.id
}


output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_ip" {
  value = aws_nat_gateway.nat_gateway.public_ip
}


# this output values uses in ec2

output "subnet_ids" {
  value = [aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id
  ]
}
output "sg_id" {
  value = aws_security_group.s_g.id
}


# this output uses in EKS module
output "private_subnet_ids" {
  value = [aws_subnet.private-subnet-1.id,
    aws_subnet.private-subnet-2.id
  ]
}
