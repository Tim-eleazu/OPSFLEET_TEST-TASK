module "eks_auth_config" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.34.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = concat(
    [
      {
        rolearn  = module.karpenter_irsa.node_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ],
    [
      for key, group in module.eks.eks_managed_node_groups : {
        rolearn  = group.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ]
  )


  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = var.eks_admin_username
      groups   = ["system:masters"]
    }
  ]

  depends_on = [
    module.eks,
    module.karpenter_irsa
  ]
}