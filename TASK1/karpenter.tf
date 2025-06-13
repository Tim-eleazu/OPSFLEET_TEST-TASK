# Create IAM Role & IRSA for Karpenter
module "karpenter_irsa" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.34"

  cluster_name                    = module.eks.cluster_name
  enable_v1_permissions           = true
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["${local.karpenter_namespace}:${local.karpenter_sa_name}"]

  queue_name = module.eks.cluster_name

  node_iam_role_additional_policies = {
    EKSWorkerPolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    ECRReadOnly     = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    VPCNetworking   = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    SSMAccess       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  create_instance_profile = true
  enable_spot_termination = true
  tags                    = local.tags
}

# Install Karpenter CRDs first
resource "helm_release" "crds" {
  name             = "karpenter-crds"
  namespace        = local.karpenter_namespace
  create_namespace = true

  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter-crd"
  version             = trimprefix(var.karpenter.version, "v")
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  depends_on = [module.eks]
}

# Deploy Karpenter Controller
resource "helm_release" "controller" {
  name             = "karpenter"
  namespace        = local.karpenter_namespace
  create_namespace = false

  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = trimprefix(var.karpenter.version, "v")
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  values = [yamlencode({
    replicas = 1
    serviceAccount = {
      name = module.karpenter_irsa.service_account
      annotations = {
        "eks.amazonaws.com/role-arn" = module.karpenter_irsa.iam_role_arn
      }
    }
    settings = {
      clusterName       = module.eks.cluster_name
      clusterEndpoint   = module.eks.cluster_endpoint
      interruptionQueue = module.karpenter_irsa.queue_name
    }
    controller = {
      logLevel = "info"
      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
  })]

  depends_on = [helm_release.crds]
}


resource "kubectl_manifest" "ec2_node_classes" {
  for_each = var.karpenter.ec2_node_classes

  server_side_apply = true
  force_conflicts   = true

  yaml_body = templatefile("${path.module}/templates/ec2_node_class.yaml.tpl", {
  name                  = each.value.name
  cluster_name          = module.eks.cluster_name
  node_role_arn         = module.karpenter_irsa.node_iam_role_arn
  ami_family            = each.value.ami_family
  ami_selector          = each.value.ami_selector_terms_alias
  disk_size             = try(each.value.disk_size, "20Gi")
  subnet_ids            = [for s in aws_subnet.private : s.id]
  security_group_ids = [module.eks.node_security_group_id]
  use_subnet_ids        = true  
  use_security_group_ids = true 
})

  depends_on = [helm_release.controller]
}

resource "kubectl_manifest" "node_pools" {
  for_each = var.karpenter.node_pools

  server_side_apply = true
  force_conflicts   = true

  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = each.value.name
    }
    spec = {
      template = {
        metadata = {
          labels = each.value.labels
        }
        spec = {
          nodeClassRef = {
            kind  = "EC2NodeClass"
            name  = each.value.ec2_node_class_ref
            group = "karpenter.k8s.aws"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = [each.value.architecture]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = [each.value.os]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = each.value.capacity_types
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = each.value.instance_types
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = local.karpenter_zones
            }
          ]
          startupTaints = [{
            key    = "node.kubernetes.io/not-ready"
            effect = "NoSchedule"
          }]
          expireAfter = "${each.value.ttl_seconds_until_expired}s"
        }
      }
      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "${each.value.ttl_seconds_after_empty}s"
      }
    }
  })

  depends_on = [
    helm_release.controller,
    kubectl_manifest.ec2_node_classes
  ]
}
