output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "private_subnet_az1" {
  value = aws_subnet.private_subnet_az1.id
}
output "private_az1" {
  value = aws_subnet.private_subnet_az1.availability_zone
}

output "private_subnet_az2" {
  value = aws_subnet.private_subnet_az2.id
}

output "private_az2" {
  value = aws_subnet.private_subnet_az2.availability_zone
}

output "private_subnet_az3" {
  value = aws_subnet.private_subnet_az3.id
}

output "private_az3" {
  value = aws_subnet.private_subnet_az3.availability_zone
}

output "public_subnet_az1" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_az1" {
  value = aws_subnet.public_subnet_az1.availability_zone
}

output "public_subnet_az2" {
  value = aws_subnet.public_subnet_az2.id
}

output "public_az2" {
  value = aws_subnet.public_subnet_az2.availability_zone
}

output "public_subnet_az3" {
  value = aws_subnet.public_subnet_az3.id
}

output "public_az3" {
  value = aws_subnet.public_subnet_az3.availability_zone
}

output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway
}

output "vpc_id" {
  value = aws_vpc.smackdab.id
}
