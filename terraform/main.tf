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

locals {
  kube_configs_azure = { for k, v in module.clusters_azure : v.cluster_name => v.kube_config }
  kube_configs_aws   = { for k, v in module.clusters_aws : v.cluster_name => v.kube_config }
  kube_configs       = merge(local.kube_configs_azure, local.kube_configs_aws)

  kube_configs_azure_b64 = [ for k, v in module.clusters_azure : base64encode(v.kube_config) ]
  kube_configs_aws_b64   = [ for k, v in module.clusters_aws : base64encode(v.kube_config) ]
  kube_configs_b64       = concat(local.kube_configs_azure_b64, local.kube_configs_aws_b64)
    
  number_clusters        = range(length(local.clusters_name))
  kubeconfig_env         = [for k, v in local.number_clusters : "${k}.yml"]

  clusters_name_azure = [for k, v in module.clusters_azure : v.cluster_name]
  clusters_name_aws   = [for k, v in module.clusters_aws : v.cluster_name]
  clusters_name       = concat(local.clusters_name_azure, local.clusters_name_aws)
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
  region     = var.aws_cluster_region != "" ? var.aws_cluster_region : "sa-east-1"
  access_key = "#{AWS_ACCESS_KEY}#"
  secret_key = "#{AWS_SECRET_KEY}#"
}

module "key_vault" {
  source = "./modules/az_keyvault"

  project_key      = "keyvaults-rg"
  vault_identifier = "kubeconfig"
  env              = "prd"
}

module "clusters_azure" {
  for_each = toset(var.azure_cluster_regions)
  source   = "./modules/az_kubernetes"

  vault_id        = module.key_vault.key_vault_id
  clusters_region = each.value
  env             = "prd"
  depends_on = [
    module.key_vault
  ]
}

module "clusters_aws" {
  for_each = var.aws_cluster_region != "" ? toset([var.aws_cluster_region]) : []
  source   = "./modules/aws_kubernetes"

  vault_id = module.key_vault.key_vault_id
  env      = "prd"
  depends_on = [
    module.key_vault
  ]
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
    kubeconfigs_b64    = "${join(",", local.kube_configs_b64)}"
    kubeconfig_env     = "${join(":", local.kubeconfig_env)}"
  }
}

resource "local_file" "ansible_inventory" {
  content  = module.ansible.inventory
  filename = "inventory"
}
