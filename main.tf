### Module Main

provider "aws" {
  region = var.aws_region
}

### Step 1 - VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.vpc_name}-vpc",
    Terraform=true,
    Owner="godartcn@gmail.com",
    Environment="prod"
  }
}

### Step 2 - Subnets (AZs)

resource "aws_subnet" "public" {
  for_each = var.azs
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}${each.key}"
  cidr_block = cidrsubnet(var.cidr_block, 4, 15 - each.value)
  tags = {
      Name = "${var.vpc_name}-public-${var.aws_region}${each.key}"
      Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = var.azs
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  availability_zone = "${var.aws_region}${each.key}"
  cidr_block = cidrsubnet(var.cidr_block, 4, each.value)
  tags = {
      Name = "${var.vpc_name}-private-${var.aws_region}${each.key}"
      Tier = "private"
  }
}

### Step 3 - Gateways

## Internet Gateway

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-internet-gateway"
  }
}

## AMI Gateway

data "aws_ami" "ami_gw" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat-hvm-*-x86_64-ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "public" {
  key_name = "public-key"
  public_key = var.public_key
}

resource "aws_instance" "nat" {
  for_each = var.azs
  security_groups = [
    aws_security_group.nat.id
  ]
  subnet_id         = aws_subnet.public[each.key].id
  ami               = data.aws_ami.ami_gw.id
  key_name          = aws_key_pair.public.key_name
  instance_type     = "t2.micro"
  source_dest_check = false

  tags = {
    Name = "${var.vpc_name}-nat-${each.key}"
  }

  depends_on = [
    aws_internet_gateway.internet_gw,
    aws_route_table_association.public,
  ]
}

resource "aws_eip" "eip_nat" {
  for_each = aws_instance.nat
  instance = each.value.id
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  for_each = aws_instance.nat
  instance_id = each.value.id
  allocation_id = aws_eip.eip_nat[each.key].id
}

## 4 Routes

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-public"
  }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
  }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gw.id
}

resource "aws_route" "private" {
  for_each = var.azs
  route_table_id = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  instance_id = aws_instance.nat[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each        = aws_route_table.private
  subnet_id       = aws_subnet.private[each.key].id
  route_table_id  = aws_route_table.private[each.key].id
}

resource "aws_security_group" "nat" {
  name        = "nat"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "SSH from Outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "NAT Access from VPC"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nat"
  }
}