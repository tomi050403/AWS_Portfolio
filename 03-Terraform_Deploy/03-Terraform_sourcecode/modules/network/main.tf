# ---
# VPC
# ---
resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr_block
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name    = "${var.project}-${var.environment}-vpc"
    Project = var.project
    Env     = var.environment
  }
}

# ---
# Subnet
# ---
# Public
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.AZ_1
  cidr_block              = var.AZ_1_publicsub
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1a"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.AZ_2
  cidr_block              = var.AZ_2_publicsub
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1c"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

#Private
resource "aws_subnet" "private_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.AZ_1
  cidr_block              = var.AZ_1_privatesub
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1a"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.AZ_2
  cidr_block              = var.AZ_2_privatesub
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1c"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

# ---
# Route Table
# ---
# Public
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-public-route-table"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

resource "aws_route_table_association" "public_route_asso_1a" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_1a.id
}

resource "aws_route_table_association" "public_route_asso_1c" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_1c.id
}

# Private
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-private-route-table"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

resource "aws_route_table_association" "private_route_asso_1a" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_1a.id
}

resource "aws_route_table_association" "private_route_asso_1c" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_1c.id
}

# ---
# Internet Gateway(public to internet)
# ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-igw"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ---
# Nat Gateway(private to internet)
# ---
resource "aws_eip" "eip_nat" {
  vpc = true

  tags = {
    Name    = "${var.project}-${var.environment}-eip-nat"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  tags = {
    Name    = "${var.project}-${var.environment}-nat-gw"
    Project = var.project
    Env     = var.environment
  }
  depends_on = [aws_eip.eip_nat]
}

resource "aws_route" "nat_route_private" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}


########################################################
# Outputs
########################################################
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_1a" {
  value = aws_subnet.public_subnet_1a.id
}

output "public_subnet_1c" {
  value = aws_subnet.public_subnet_1c.id
}

output "private_subnet_1a" {
  value = aws_subnet.private_subnet_1a.id
}

output "private_subnet_1c" {
  value = aws_subnet.private_subnet_1c.id
}