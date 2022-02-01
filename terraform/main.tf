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
}


module "my_cluster" {
  source = "./modules/az_kubernetes"

  env              = "prd"
}

