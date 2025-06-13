output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "karpenter_irsa_arn" {
  description = "IAM role ARN for Karpenter service account"
  value       = module.karpenter_irsa.iam_role_arn
}

output "karpenter_instance_profile_name" {
  description = "Instance profile name for Karpenter nodes"
  value       = module.karpenter_irsa.instance_profile_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID used for the EKS cluster"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used for the EKS cluster"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  description = "Public subnet IDs used for the EKS cluster"
  value       = [for s in aws_subnet.public : s.id]
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "karpenter_version" {
  description = "Installed Karpenter version"
  value       = var.karpenter.version
}
