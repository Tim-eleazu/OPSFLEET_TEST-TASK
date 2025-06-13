resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr
  enable_dns_support   = var.vpc.enable_dns_support
  enable_dns_hostnames = var.vpc.enable_dns_hostnames
  tags = merge(var.default_tags, {
    Name = "${var.vpc.name}-vpc"
  })
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.default_tags, {
    Name = "${var.vpc.name}-pub-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.default_tags, {
    Name                     = "${var.vpc.name}-priv-${count.index + 1}"
    Tier                     = "private"
    "karpenter.sh/discovery" = var.eks.cluster_name
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.default_tags, { Name = "${var.vpc.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.default_tags, { Name = "${var.vpc.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  tags = merge(var.default_tags, { Name = "${var.vpc.name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.default_tags, { Name = "${var.vpc.name}-nat" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.default_tags, { Name = "${var.vpc.name}-private-rt" })
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
