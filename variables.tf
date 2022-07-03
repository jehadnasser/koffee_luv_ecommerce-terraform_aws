variable "region" {
   description = "AWS region"
   default     = "us-east-1"
   type        = string
}

variable "namespace" {
    description = "The project namespace to use for unique resource naming"
    type        = string
}

variable "vpc_cidr_prefix" {
    description = "The CIDR block prefix for the VPC"
    type        = string  
}
