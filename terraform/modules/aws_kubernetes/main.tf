terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.29.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">=2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">=3.1.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.1"
    }
  }
  required_version = ">= 1.0.0"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

locals {
  cluster_name = "eks-${random_string.suffix.result}-${var.env}"
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.cluster.token
      }
    }]
  })
}

resource "aws_key_pair" "eks_nodes" {
  key_name   = "eks-nodes-${random_string.suffix.result}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsCW7VzeAr/T3mNxtLxl8w4p9L/6//ghL7JgvOZD4EXvL1Y+e/qB/eVTlKbqdaAuSQ8UDdkJ+wMvDHMXA3Pf2NB6iWXQKC01YVr2om8lE5k/ftLB48LdshsqyOKKRAh3i7yZwJdptyX9sxx1cdTwXZSqDAadUgb7qoMyWkZ9pccFfJQwV4TO71A3sJtC5U7BJpsYGbmWktPhfUdw6ysNbupUKjo32oL4co8Sezl24RhmUJTnLqA4ZKfntX9SwKfImP8OkEKu/OnwX/tuBjtCTqEMRR5ivQ45FJtk/Uw0MsmOweZJ66ehL0VwljYoLiEPKYRx4gH1GrKzZrRlYCe4r7pEQ+EpE3Iug7fR6epoWejn4ECPhndlGIBoy7gVCfP7AQmbvuLOqlIFxPzU26Fo9LEwf3D/yvoH1ZFMbG42PDzlfEFpH2xqis8V8tmQuJGXGUt9kakzXalfO7JgGs8PigPgAnFyVWvmOngR1nJj5YR3oI0IasQ0sDjbfDtkc2xXZvD/Lba3P8QF2KrKkExvCEfq1Bz8Hc/Ih48zISN5/MIB+GdTVflJsrI3Im2wY5SmFF2RKqO2726xUlFJ4EGN/gS2KkzA0BYxSqCYxTlm4KIUzY8cy2hf0dIV1HgPTTSg/0/kYQ+82D5rVK29yTRKDCjQhBXGmcKoEU4Ye5VzjXKw== leo.gcs@poli.ufrj.br"
}

/* Creating EKS*/

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">=17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.vpc.vpc_id

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = [var.node_size]
    key_name       = aws_key_pair.eks_nodes.key_name
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = var.number_nodes_per_cluster
      max_size     = var.number_nodes_per_cluster
      desired_size = var.number_nodes_per_cluster

      instance_types = [var.node_size]
      capacity_type  = "SPOT"
    }
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

#resource "azurerm_key_vault_secret" "secret" {
#  name         = local.cluster_name
#  value        = local.kubeconfig
#  key_vault_id = var.vault_id

#  tags = {
#    env = var.env
#  }
#}