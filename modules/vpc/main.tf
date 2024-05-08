resource "aws_vpc" "my-vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }

}


# create public subnet az1

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  availability_zone       = var.availability_zone[0]
  cidr_block              = var.az_public_cidr[0]
  map_public_ip_on_launch = var.public_ip

  tags = {
    Name = "public-subnet-1"
  }
}

# create public subnet az2

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  availability_zone       = var.availability_zone[1]
  cidr_block              = var.az_public_cidr[1]
  map_public_ip_on_launch = var.public_ip

  tags = {
    Name = "public-subnet-2"
  }
}


# create route table and public route i.e. add internet gateway in public route table with internet access 0.0.0.0/0
# we create public route for internet access

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

# associate public subnet 1 to public route table

resource "aws_route_table_association" "public_subnet_1_route" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-rt.id
}

# associate public subnet 2 to public route table

resource "aws_route_table_association" "public_subnet_2_route" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-rt.id
}


# create private subnet 1

resource "aws_subnet" "private-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  availability_zone       = var.availability_zone[0]
  cidr_block              = var.az_private_cidr[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

# create private subnet 2

resource "aws_subnet" "private-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  availability_zone       = var.availability_zone[1]
  cidr_block              = var.az_private_cidr[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}

# create private route table
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "private-route-table"
  }
}

# associate private subnet route to private route table
resource "aws_route_table_association" "private_subnet_route_1" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private_subnet_route_2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-rt.id
}

# create nat-gateway
resource "aws_eip" "elastic_ip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "nat_gateway"
  }
}

## ensure route
resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private-rt.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}




# security group
resource "aws_security_group" "s_g" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "demo-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_security_group.s_g.id
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.my-vpc.cidr_block
  from_port         = 22
  to_port           = 22

}

resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv4" {
  security_group_id = aws_security_group.s_g.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

}
resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv6" {
  security_group_id = aws_security_group.s_g.id
  ip_protocol       = -1
  cidr_ipv6         = "::/0"

}
