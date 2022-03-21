terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
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

provider "aws" {
  region = var.clusters_region
}

/* kubernetes config workaround for EKS*/
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

data "aws_availability_zones" "available" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "eks-${var.clusters_region}-${random_string.suffix.result}-${var.env}"
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

/* Creating cluster network */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">=3.2.0"

  name                 = "eks-${var.clusters_region}-${var.env}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc_private_ip
  public_subnets       = var.vpc_public_ip
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

/* Creating security groups*/
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one_${random_string.suffix.result}_${var.env}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr,
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management_${random_string.suffix.result}_${var.env}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr,
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

/* Creating EKS*/

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">=17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets

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

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 50
    instance_types         = [var.node_size]
    vpc_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = var.number_nodes_per_cluster
      max_size     = var.number_nodes_per_cluster
      desired_size = var.number_nodes_per_cluster

      instance_types = [var.node_size]
      capacity_type  = "SPOT"
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

