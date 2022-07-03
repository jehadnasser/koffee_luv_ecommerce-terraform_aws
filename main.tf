module "networking" {
    source              = "./modules/networking"
    namespace           = var.namespace
    vpc_cidr_prefix     = var.vpc_cidr_prefix
    environment         = "dev"
    availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    public_subnets      = {
        "us-east-1a" = "${var.vpc_cidr_prefix}.1.0/24"
        "us-east-1b" = "${var.vpc_cidr_prefix}.2.0/24"
        "us-east-1c" = "${var.vpc_cidr_prefix}.3.0/24"
    }
    private_subnets     = {
        "us-east-1a" = "${var.vpc_cidr_prefix}.4.0/24"
        "us-east-1b" = "${var.vpc_cidr_prefix}.5.0/24"
        "us-east-1c" = "${var.vpc_cidr_prefix}.6.0/24"
    }
    db_subnets     = {
        "us-east-1a" = "${var.vpc_cidr_prefix}.8.0/24"
        "us-east-1b" = "${var.vpc_cidr_prefix}.9.0/24"
        "us-east-1c" = "${var.vpc_cidr_prefix}.10.0/24"
    }
}