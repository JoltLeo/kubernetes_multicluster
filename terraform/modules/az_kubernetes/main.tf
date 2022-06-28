terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.29.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.1.0"
    }
  }
  required_version = ">= 1.0.0"
}

resource "random_integer" "random_id" {
  min = 1
  max = 5000
}

resource "azurerm_resource_group" "rg_cluster" {
  name     = "aks-${var.clusters_region}-${random_integer.random_id.result}-rg"
  location = var.clusters_region
}

resource "azurerm_kubernetes_cluster" "az_cluster" {
  name                = "aks-${var.clusters_region}-${random_integer.random_id.result}"
  location            = azurerm_resource_group.rg_cluster.location
  resource_group_name = azurerm_resource_group.rg_cluster.name
  dns_prefix          = "aks${var.clusters_region}${random_integer.random_id.result}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "akspool${random_integer.random_id.result}"
    node_count = var.number_nodes_per_cluster
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "kubeadmin"
    ssh_key {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsCW7VzeAr/T3mNxtLxl8w4p9L/6//ghL7JgvOZD4EXvL1Y+e/qB/eVTlKbqdaAuSQ8UDdkJ+wMvDHMXA3Pf2NB6iWXQKC01YVr2om8lE5k/ftLB48LdshsqyOKKRAh3i7yZwJdptyX9sxx1cdTwXZSqDAadUgb7qoMyWkZ9pccFfJQwV4TO71A3sJtC5U7BJpsYGbmWktPhfUdw6ysNbupUKjo32oL4co8Sezl24RhmUJTnLqA4ZKfntX9SwKfImP8OkEKu/OnwX/tuBjtCTqEMRR5ivQ45FJtk/Uw0MsmOweZJ66ehL0VwljYoLiEPKYRx4gH1GrKzZrRlYCe4r7pEQ+EpE3Iug7fR6epoWejn4ECPhndlGIBoy7gVCfP7AQmbvuLOqlIFxPzU26Fo9LEwf3D/yvoH1ZFMbG42PDzlfEFpH2xqis8V8tmQuJGXGUt9kakzXalfO7JgGs8PigPgAnFyVWvmOngR1nJj5YR3oI0IasQ0sDjbfDtkc2xXZvD/Lba3P8QF2KrKkExvCEfq1Bz8Hc/Ih48zISN5/MIB+GdTVflJsrI3Im2wY5SmFF2RKqO2726xUlFJ4EGN/gS2KkzA0BYxSqCYxTlm4KIUzY8cy2hf0dIV1HgPTTSg/0/kYQ+82D5rVK29yTRKDCjQhBXGmcKoEU4Ye5VzjXKw== leo.gcs@poli.ufrj.br"
    }
  }

  tags = {
    env = var.env
  }
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "aks-${var.clusters_region}-${random_integer.random_id.result}"
  value        = azurerm_kubernetes_cluster.az_cluster.kube_config_raw
  key_vault_id = var.vault_id

  tags = {
    env = var.env
  }
}