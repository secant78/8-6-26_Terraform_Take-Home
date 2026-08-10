output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ec2_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.ec2.private_ip
}