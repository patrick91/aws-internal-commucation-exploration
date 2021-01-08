locals {
  vpc_cidr_block      = "10.0.0.0/16"
  subnet_a_cidr_block = "10.0.0.0/20"
  subnet_b_cidr_block = "10.0.16.0/20"
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "vpc_public_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet_a_cidr_block
  availability_zone = "us-east-1a"
  tags = {
    Name    = "p-subnet-a"
    Project = "Services POC"
  }
}

resource "aws_subnet" "vpc_public_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.subnet_b_cidr_block
  availability_zone = "us-east-1b"
  tags = {
    Name    = "p-subnet-b"
    Project = "Services POC"
  }
}

resource "aws_internet_gateway" "vpc_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = "p-vpc-gateway"
    Project = "Services POC"
  }
}

resource "aws_route_table" "vpc_public_subnet_route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gateway.id
  }
}

resource "aws_route_table_association" "vpc_public_subnet_route_assoc_a" {
  subnet_id      = aws_subnet.vpc_public_subnet_a.id
  route_table_id = aws_route_table.vpc_public_subnet_route.id
}

resource "aws_route_table_association" "vpc_public_subnet_route_assoc_b" {
  subnet_id      = aws_subnet.vpc_public_subnet_b.id
  route_table_id = aws_route_table.vpc_public_subnet_route.id
}
