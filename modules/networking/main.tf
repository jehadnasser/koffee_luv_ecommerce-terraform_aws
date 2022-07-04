data "aws_availability_zones" "available" {}

# Step1 - VPC
resource "aws_vpc" "main_vpc" {
    cidr_block              = "${var.vpc_cidr_prefix}.0.0/16"
    enable_dns_hostnames    = true

    tags = {
        Terraform   = "true"
        Name        = "${var.namespace}-main_vpc"
        Environment = "${var.environment}"
    }
}

# Step2 - IGW
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name = "${var.namespace}-IGW"
        Environment = "${var.environment}"
    }
}

# Step3 - Subnets
resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnets)

    vpc_id                      = aws_vpc.main_vpc.id
    availability_zone           = element(var.availability_zones, count.index)
    cidr_block                  = lookup(
        var.public_subnets, 
        element(
            var.availability_zones, 
            count.index
        )
    )
    depends_on = [
      aws_internet_gateway.igw
    ]
    tags = {
        Name = "${var.namespace}-${format("public_subnet-%03d", count.index)}"
        Environment = "${var.environment}"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnets)

    vpc_id                      = aws_vpc.main_vpc.id
    availability_zone           = element(var.availability_zones, count.index)
    cidr_block                  = lookup(
        var.private_subnets, 
        element(
            var.availability_zones, 
            count.index
        )
    )
    tags = {
        Name = "${var.namespace}-${format("private_subnet-%03d", count.index)}"
        Environment = "${var.environment}"
    }
}

resource "aws_subnet" "db_subnets" {
    count = length(var.db_subnets)

    vpc_id                      = aws_vpc.main_vpc.id
    availability_zone           = element(var.availability_zones, count.index)
    cidr_block                  = lookup(
        var.db_subnets, 
        element(
            var.availability_zones, 
            count.index
        )
    )
    tags = {
        Name = "${var.namespace}-${format("db_subnet-%03d", count.index)}"
        Environment = "${var.environment}"
    }
}

# Step4 - NGWs and its EIPs
resource "aws_eip" "ngw_eip" {
    count = length(var.public_subnets)

    vpc           = true
    depends_on    = [aws_internet_gateway.igw]
    tags = {
        Name = "${var.namespace}-eip"
        Environment = "${var.environment}"
    }
}

resource "aws_nat_gateway" "ngw" {
    count         = length(var.public_subnets)

    allocation_id = aws_eip.ngw_eip[count.index].id
    subnet_id     = aws_subnet.public_subnets[count.index].id
    depends_on    = [aws_internet_gateway.igw]

    tags          = {
      Name = "${var.namespace}-ngw"
      Environment = "${var.environment}"
    }
}

# Step5 - Route Tables
# public: for any traffic leaves PubSubs to dest 0.0.0.0/0 
# goes to IGW directly
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name           = "${var.namespace}-public_route_table"
        Environment    = var.environment
    }
}

resource "aws_route" "to_public_internet_route" {
    route_table_id           = aws_route_table.public_route_table.id
    destination_cidr_block   = "0.0.0.0/0"
    # goes to IGW
    gateway_id               = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_route_table_assoc" {
    count           = length(var.public_subnets)

    subnet_id       = aws_subnet.public_subnets[count.index].id
    route_table_id  = aws_route_table.public_route_table.id
}

# private: for any traffic leaves PriSubs to dest 0.0.0.0/0 
# goes to NatGW then IGW or dropped
resource "aws_route_table" "private_route_table" {
    count  = length(var.availability_zones)

    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name           = "${var.namespace}-${format("pri_route_table-%03d", count.index)}"
        Environment    = var.environment
    }
}

resource "aws_route" "to_ngw_route" {
    count                    = length(var.availability_zones)

    route_table_id           = aws_route_table.private_route_table[count.index].id
    destination_cidr_block   = "0.0.0.0/0"
    nat_gateway_id           = aws_nat_gateway.ngw[count.index].id
}

resource "aws_route_table_association" "private_subnet_route_table_assoc" {
    count           = length(var.private_subnets)

    subnet_id       = aws_subnet.private_subnets[count.index].id
    route_table_id  = aws_route_table.private_route_table[count.index].id
}

resource "aws_route_table_association" "db_subnet_route_table_assoc" {
    count           = length(var.db_subnets)

    subnet_id       = aws_subnet.db_subnets[count.index].id
    route_table_id  = aws_route_table.private_route_table[count.index].id
}