output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc.id
}