variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Global tags applied to all created AWS resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "autoscaling-infra"
    Terraform   = "enabled"
  }
}

variable "vpc" {
  description = "Custom VPC configuration for EKS deployment"
  type = object({
    name                   = string
    cidr                   = string
    enable_nat_gateway     = bool
    public_subnets         = list(string)
    private_subnets        = list(string)
    enable_dns_hostnames   = bool
    enable_dns_support     = bool
    single_nat_gateway     = bool
    one_nat_gateway_per_az = bool
  })
}

variable "eks" {
  description = "Amazon EKS cluster and managed node group configuration"
  type = object({
    cluster_name                         = string
    cluster_version                      = string
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    managed_node_groups                  = map(any)
    managed_node_group_defaults          = any
  })
  default = {
    cluster_name                         = "autoscaling-cluster"
    cluster_version                      = "1.32"
    cluster_endpoint_public_access       = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
    managed_node_groups = {
      core = {
        name           = "core-nodes"
        instance_types = ["t4g.small"]
        ami_type       = "AL2023_ARM_64_STANDARD"
        min_size       = 1
        max_size       = 3
        desired_size   = 2
        capacity_type  = "ON_DEMAND"
        lifecycle = {
          create_before_destroy = true
        }
      }
    }
    managed_node_group_defaults = {
      ami_type       = "AL2023_ARM_64"
      instance_types = ["t4g.small"]
      disk_size      = 20
    }
  }
}

variable "karpenter" {
  description = "Karpenter autoscaler setup with EC2 node class and node pools"
  type = object({
    version          = string
    ec2_node_classes = map(any)
    node_pools       = map(any)
  })
  default = {
    version = "v1.3.1"

    ec2_node_classes = {
      base = {
        name                      = "base-node-class"
        ami_family                = "AL2023"
        ami_selector_terms_alias = "al2023@latest"
        disk_size                 = "20Gi"
        use_subnet_discovery         = true
        use_security_group_discovery = true
      }
    }

    node_pools = {
      amd_nodes = {
        name                    = "spot-x86"
        ec2_node_class_ref      = "base-node-class"
        instance_types          = [
          "t3.small", "t3a.small", "t3.medium", "t3a.medium",
          "m5.medium", "m5.large", "m5.xlarge",
          "c5.medium", "c5.large", "c5.xlarge",
          "r5.medium", "r5.large", "r5.xlarge",
          "m6i.medium", "m6i.large", "m6i.xlarge",
          "c6i.medium", "c6i.large", "c6i.xlarge",
          "r6i.medium", "r6i.large", "r6i.xlarge"
        ]
        capacity_types            = ["spot", "on-demand"]
        architecture              = "amd64"
        os                        = "linux"
        ttl_seconds_after_empty   = 30
        ttl_seconds_until_expired = 2592000
        labels = {
          "kubernetes.io/arch"         = "amd64"
          "node-type"                  = "x86"
          "karpenter.sh/capacity-type" = "spot"
          "nodeManager"                = "karpenter"
        }
      }

      arm_nodes = {
        name                    = "spot-arm"
        ec2_node_class_ref      = "base-node-class"
        instance_types          = [
          "t4g.small", "t4g.medium",
          "m6g.medium", "m6g.large", "m6g.xlarge",
          "c6g.medium", "c6g.large", "c6g.xlarge",
          "r6g.medium", "r6g.large", "r6g.xlarge",
          "m7g.medium", "m7g.large", "m7g.xlarge",
          "c7g.medium", "c7g.large", "c7g.xlarge",
          "r7g.medium", "r7g.large", "r7g.xlarge",
          "m8g.medium", "m8g.large", "m8g.xlarge",
          "c8g.medium", "c8g.large", "c8g.xlarge",
          "r8g.medium", "r8g.large", "r8g.xlarge",
          "x8g.medium", "x8g.large", "x8g.xlarge"
        ]
        capacity_types            = ["spot", "on-demand"]
        architecture              = "arm64"
        os                        = "linux"
        ttl_seconds_after_empty   = 30
        ttl_seconds_until_expired = 2592000
        labels = {
          "kubernetes.io/arch"         = "arm64"
          "node-type"                  = "arm"
          "karpenter.sh/capacity-type" = "spot"
          "nodeManager"                = "karpenter"
        }
      }
    }
  }
}

variable "eks_admin_username" {
  description = "Admin IAM user to be granted full access to the EKS cluster"
  type        = string
}