# create vpc
resource "aws_vpc" "smackdab" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.smackdab.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}
//---------------------------------------------------------------------------------------------
# create public subnet az1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public_subnet_az1"
  }
}

# create public subnet az2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public_subnet_az2"
  }
}

resource "aws_subnet" "public_subnet_az3" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.public_subnet_az3_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public_subnet_az3"
  }
}

//---------------------------------------------------------------------------------------------
# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.smackdab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project_name}-public_route_table"
  }
}

# associate public subnet az1 to "public route table"
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

# associate public subnet az2 to "public route table"
resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_az3_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az3.id
  route_table_id = aws_route_table.public_route_table.id
}
//---------------------------------------------------------------------------------------------
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private_subnet_az1"
  }
}

resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private_subnet_az2"
  }
}

resource "aws_subnet" "private_subnet_az3" {
  vpc_id                  = aws_vpc.smackdab.id
  cidr_block              = var.private_subnet_az3_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private_subnet_az3"
  }
}

resource "aws_eip" "nat" {
  tags = {
    Name = "${var.project_name}-eip"
  }
}

//---------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_az1.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# resource "aws_route" "private_nat_gateway" {
#   count                  = var.enable_nat_gateway ? 1 : 0
#   route_table_id         = aws_route_table.private_nat.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat_gw.id
# }


//---------------------------------------------------------------------------------------------
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.smackdab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${var.project_name}-nat-routetable"
  }
}



resource "aws_route_table_association" "private_nat_az1" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_route_table_association" "private_nat_az2" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_nat_az3" {
  subnet_id      = aws_subnet.private_subnet_az3.id
  route_table_id = aws_route_table.private_route_table.id
}
