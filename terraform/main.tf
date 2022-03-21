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
      source = "hashicorp/azuread"
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
  tenant_id            = "bd41b059-b038-488a-bdb8-e0d259819fc5"
  subscription_id      = "842357d2-6cd7-475f-a4ad-d26a927f1a9f"
  client_id            = "6749c383-3df2-4028-a974-7711d176cd67"
  client_secret        = "#{APP_SECRET}#"
}

provider "aws" {
  region     = "sa-east-1"
  access_key = "#{AWS_ACCESS_KEY}#"
  secret_key = "#{AWS_SECRET_KEY}#"
}

module "my_cluster_azure" {
  source = "./modules/az_kubernetes"

  env = "prd"
}

  module "my_cluster_aws" {
  source = "./modules/aws_kubernetes"

  env = "prd"
}
