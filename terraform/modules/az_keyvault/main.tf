terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.29.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">1.0.0"
    }
  }
  required_version = ">= 0.13"
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name     = var.project_key
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "azdo-${var.vault_identifier}-${var.env}"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    env  = var.env
  }
}

resource "azurerm_key_vault_access_policy" "devops_agent" {
  key_vault_id       = azurerm_key_vault.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "set",
    "get",
    "list",
    "delete",
    "purge",
    "recover",
  ]
  certificate_permissions = [
    "get",
    "list",
    "getIssuers",
    "ListIssuers",
  ]
}

resource "azurerm_key_vault_access_policy" "secret_admins" {
  for_each = toset(var.secret_admins)

  key_vault_id       = azurerm_key_vault.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = each.key
  secret_permissions = [
    "set",
    "get",
    "list",
    "delete",
    "purge",
    "recover",
  ]
}

/* Assign kv readers */
data "azuread_service_principal" "secret_readers" {
  for_each     = toset(var.secret_readers_apps)
  display_name = each.key
}

data "azuread_group" "secret_readers" {
  for_each     = toset(var.secret_readers_groups)
  display_name = each.key
}

data "azuread_service_principal" "certificate_managers" {
  for_each     = toset(var.certificate_managers_apps)
  display_name = each.key
}

resource "azurerm_role_assignment" "readers" {
  for_each = merge(data.azuread_service_principal.secret_readers, data.azuread_group.secret_readers, data.azuread_service_principal.certificate_managers)

  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Reader"
  principal_id         = each.value.object_id
}

resource "azurerm_role_assignment" "admin_readers" {
  for_each = toset(var.secret_admins)

  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Reader"
  principal_id         = each.key
}

resource "azurerm_key_vault_access_policy" "readers" {
  for_each = merge(data.azuread_service_principal.secret_readers, data.azuread_group.secret_readers)

  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  secret_permissions = [
    "get",
    "list",
  ]
}

resource "azurerm_key_vault_access_policy" "certificate_managers" {
  for_each = data.azuread_service_principal.certificate_managers

  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  certificate_permissions = [
    "get",
    "backup",
    "create",
    "delete",
    "deleteIssuers",
    "import",
    "manageContacts",
    "manageIssuers",
    "purge",
    "recover",
    "restore",
    "update",
    "setIssuers",
    "list",
    "getIssuers",
    "listIssuers",
  ]
}