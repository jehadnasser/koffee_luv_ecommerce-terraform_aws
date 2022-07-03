variable "namespace" {
    type = string
}

variable "vpc_cidr_prefix" {
    type = string
}

variable "environment" {
    description = "Environment name"
}

variable "availability_zones" {
    type = list
    description = "Availability zones"
}

variable "public_subnets" {
    type = map
    description = "Map of AZ as keys and subnets as values"
    default = {}
}

variable "private_subnets" {
    type = map
    description = "Map of AZ as keys and subnets as values"
}

variable "db_subnets" {
    type = map
    description = "Map of AZ as keys and subnets as values"
    default = {}
}
