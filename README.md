# Assessment Summary

## Task 1 — `TASK1/`
## Automate AWS EKS with Karpenter, Graviton & Spot**  
- Deploys an EKS cluster (latest version) in a dedicated VPC  
- Configures Karpenter node pools for both x86 and ARM/Graviton instances  
- Includes a README showing how developers can schedule pods on either architecture  

## Task 2 — `TASK2/`
## “Innovate Inc.” Cloud Architecture Design (AWS-specific)

- **Environment Structure:**  
  AWS Organization with three accounts (Dev, Staging, Prod) plus a Shared-Services account  

- **Network:**  
  Multi-AZ VPC with public, private and database-only subnets; Internet Gateway; per-AZ NAT Gateways; VPC Endpoints (S3, ECR, Secrets Manager); VPC Flow Logs  

- **Compute:**  
  Amazon EKS managed control plane; three node groups (Dev on small on-demand, Prod on larger on-demand, Spot for non-critical workloads); Cluster Autoscaler; HPA/VPA; Pod Disruption Budgets  

- **CI/CD & Containers:**  
  Terraform IaC; AWS CodeBuild pipeline; Amazon ECR (KMS-encrypted); Trivy image scans; Helm + Argo CD (or Flux) for GitOps; Canary/Blue-Green deployments  

- **Database:**  
  Amazon RDS for PostgreSQL (Multi-AZ); automated daily snapshots + PITR; read replicas; cross-region snapshot copy for DR  

- **Security & Compliance:**  
  IAM least-privilege roles; AWS KMS keys per environment; AWS Systems Manager Session Manager (no SSH); CloudWatch Logs; AWS Config & GuardDuty  

- **Cost Optimization:**  
  AWS Compute Optimizer recommendations; Spot Instances for batch workloads; AWS Savings Plans; S3 lifecycle policies (IA/Glacier)  

