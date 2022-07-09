terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatepfaccount"
    container_name       = "tfstate-container"
    key                  = "main.tfstate"
    tenant_id            = "bd41b059-b038-488a-bdb8-e0d259819fc5"
    subscription_id      = "21598ca8-3b69-42da-98d7-eb0867540218"
    client_id            = "6749c383-3df2-4028-a974-7711d176cd67"
    client_secret        = "#{APP_SECRET}#"
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.6.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">=1.0.5"
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
    }
  }
  tenant_id       = "bd41b059-b038-488a-bdb8-e0d259819fc5"
  subscription_id = "842357d2-6cd7-475f-a4ad-d26a927f1a9f"
  client_id       = "6749c383-3df2-4028-a974-7711d176cd67"
  client_secret   = "#{APP_SECRET}#"
}

provider "azuread" {
  client_id     = "6749c383-3df2-4028-a974-7711d176cd67"
  client_secret = "#{APP_SECRET}#"
  tenant_id     = "bd41b059-b038-488a-bdb8-e0d259819fc5"
}

provider "aws" {
  region     = var.aws_cluster_region != "" ? var.aws_cluster_region : "us-east-1"
  access_key = "#{AWS_ACCESS_KEY}#"
  secret_key = "#{AWS_SECRET_KEY}#"
}

locals {
  infra                       = yamldecode(file("clusters.yml"))
  az_clusters_regions         = length(local.infra.azure_clusters) != 0 ? tolist(keys(local.infra.azure_clusters)) : ""
  aws_clusters_regions        = length(local.infra.aws_clusters) != 0 ? tolist(keys(local.infra.aws_clusters)) : ""
  aws_clusters_vpc_cidr       = length(local.infra.aws_clusters) != 0 ? [for i in local.infra.aws_clusters : i["vpc_cidr"]] : ""
  aws_clusters_vpc_private_ip = length(local.infra.aws_clusters) != 0 ? [for i in local.infra.aws_clusters : i["vpc_private_ip"]] : ""
  aws_clusters_vpc_public_ip  = length(local.infra.aws_clusters) != 0 ? [for i in local.infra.aws_clusters : i["vpc_public_ip"]] : ""

  kube_configs_azure_b64 = [for k, v in module.clusters_azure : base64encode(v.kube_config)]
  kube_configs_aws_b64   = [for k, v in module.clusters_aws : base64encode(v.kube_config)]
  kube_configs_b64       = concat(local.kube_configs_azure_b64, local.kube_configs_aws_b64)

  number_clusters = range(length(local.clusters_name))
  kubeconfig_env  = [for k, v in local.number_clusters : "${k}.yml"]

  clusters_name_azure = [for k, v in module.clusters_azure : v.cluster_name]
  clusters_name_aws   = [for k, v in module.clusters_aws : v.cluster_name]
  clusters_name       = concat(local.clusters_name_azure, local.clusters_name_aws)
}

module "key_vault" {
  source = "./modules/az_keyvault"

  project_key      = "keyvaults-rg"
  vault_identifier = "kubeconfig"
  env              = "prd"
}

module "clusters_azure" {
  count  = length(local.az_clusters_regions)
  source = "./modules/az_kubernetes"

  vault_id        = module.key_vault.key_vault_id
  clusters_region = element(local.az_clusters_regions, count.index)
  env             = "prd"
  depends_on = [
    module.key_vault
  ]
}

module "clusters_aws" {
  count  = length(local.aws_clusters_regions)
  source = "./modules/aws_kubernetes"

  cluster_region = element(local.aws_clusters_regions, count.index)
  vpc_cidr       = element(local.aws_clusters_vpc_cidr, count.index)
  vpc_private_ip = element(local.aws_clusters_vpc_private_ip, count.index)
  vpc_public_ip  = element(local.aws_clusters_vpc_public_ip, count.index)

  vault_id = module.key_vault.key_vault_id
  env      = "prd"
}

module "ansible" {
  source = "./modules/ansible_inventory"
  hosts = [
    {
      group      = "kubernetes"
      name       = "localhost"
      ip_address = "localhost"
    },
  ]
  extra_vars = {
    ansible_connection = "local"
    clusters_name      = "${join(",", local.clusters_name)}"
    master_cluster     = "${local.clusters_name[0]}"
    kubeconfigs_b64    = "${join(",", local.kube_configs_b64)}"
    kubeconfig_env     = "${join(":", local.kubeconfig_env)}"
  }
}

resource "local_file" "ansible_inventory" {
  content  = module.ansible.inventory
  filename = "inventory"
}
