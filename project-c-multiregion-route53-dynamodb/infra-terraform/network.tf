# Region A VPC
resource "aws_vpc" "a" {
  provider             = aws.a
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc-a" }
}

resource "aws_internet_gateway" "a" {
  provider = aws.a
  vpc_id   = aws_vpc.a.id
}

resource "aws_subnet" "a_public_1" {
  provider                = aws.a
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region_a}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-a-public-1" }
}

resource "aws_subnet" "a_public_2" {
  provider                = aws.a
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region_a}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-a-public-2" }
}

resource "aws_route_table" "a" {
  provider = aws.a
  vpc_id   = aws_vpc.a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.a.id
  }
}

resource "aws_route_table_association" "a_1" {
  provider       = aws.a
  subnet_id      = aws_subnet.a_public_1.id
  route_table_id = aws_route_table.a.id
}

resource "aws_route_table_association" "a_2" {
  provider       = aws.a
  subnet_id      = aws_subnet.a_public_2.id
  route_table_id = aws_route_table.a.id
}

# Region B VPC
resource "aws_vpc" "b" {
  provider             = aws.b
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc-b" }
}

resource "aws_internet_gateway" "b" {
  provider = aws.b
  vpc_id   = aws_vpc.b.id
}

resource "aws_subnet" "b_public_1" {
  provider                = aws.b
  vpc_id                  = aws_vpc.b.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "${var.region_b}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-b-public-1" }
}

resource "aws_subnet" "b_public_2" {
  provider                = aws.b
  vpc_id                  = aws_vpc.b.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "${var.region_b}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-b-public-2" }
}

resource "aws_route_table" "b" {
  provider = aws.b
  vpc_id   = aws_vpc.b.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.b.id
  }
}

resource "aws_route_table_association" "b_1" {
  provider       = aws.b
  subnet_id      = aws_subnet.b_public_1.id
  route_table_id = aws_route_table.b.id
}

resource "aws_route_table_association" "b_2" {
  provider       = aws.b
  subnet_id      = aws_subnet.b_public_2.id
  route_table_id = aws_route_table.b.id
}
