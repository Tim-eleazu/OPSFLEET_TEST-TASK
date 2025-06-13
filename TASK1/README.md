
[![Terraform](https://img.shields.io/badge/Terraform-1.8+-5F43E9?logo=terraform)](https://www.terraform.io/)
[![Karpenter](https://img.shields.io/badge/Karpenter-Autoscaler-FF9900?logo=amazon-eks)](https://karpenter.sh/)

This repository provisions an AWS EKS cluster using Terraform and installs [Karpenter](https://karpenter.sh) to enable dynamic autoscaling with support for both x86 (AMD64) and ARM64 (Graviton) architectures using Spot instances for cost optimization.

---

## Table of Contents

- [Features Provisioned](#-features-provisioned)
- [Node Pools Overview](#-node-pools-overview)
- [Usage](#-usage)
  - [Configure AWS Credentials](#1-configure-aws-credentials)
  - [Initialize & Apply Terraform](#2-initialize--apply-terraform)
  - [Configure kubectl](#3-configure-kubectl)
  - [Deploy Sample Workloads](#4-deploy-sample-workloads)
  - [Verify Pod Scheduling](#5-verify-pod-scheduling)
- [ Expected Outcome](#-expected-outcome)

---

##  Features Provisioned

### Terraform Modules Include:
- **VPC**: Dedicated VPC with private and public subnets across 3 Availability Zones.
- **EKS Cluster**: Managed Kubernetes control plane with the latest available version.
- **Karpenter**:
  - Helm-based installation and CRDs
  - `EC2NodeClass` definitions for both architectures
  - `NodePool` resources:
    - `default-x86` (amd64 + Spot)
    - `default-arm64` (arm64 + Spot)

---

## Node Pools Overview

| Node Pool        | Architecture | Capacity Type | Example Instance Types               |
|------------------|--------------|----------------|---------------------------------------|
| `default-x86`    | `amd64`      | `spot`         | t3, m5, c5, m6i, r5, etc.             |
| `default-arm64`  | `arm64`      | `spot`         | c6g, r6g, t4g (AWS Graviton family)   |

---

## Usage

### 1. Configure AWS Credentials

```bash```
export AWS_PROFILE=your-profile

### 2. Terraform Configuration

```terraform init```

```terraform plan -var-file="terraform.tfvars"```

```terraform apply -var-file="terraform.tfvars"```


### 1. Configure kubectl

```aws eks update-kubeconfig --region us-east-1 --name autoscailing-cluster```


### Deploy Workloads
``` kubectl apply -f manifests/spot-instances/spot-arm64.yaml ```

``` kubectl apply -f manifests/spot-instances/spot-x86.yaml ```


### Verify Pod Scheduling

``` kubectl get pods -l app=nginx-spot-x86```

``` kubectl describe pods <name of pod>```

``` kubectl get node -o wide```


``` kubectl describe node <name of newly provisioned node>```