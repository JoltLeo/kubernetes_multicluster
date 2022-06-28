## Descrição
Módulo para criação de keyvaults na Azure padrão BBM

## Política de acesso padrão
Serão atribuídas politicas de gerenciamento de secrets tanto para o devops_agent que o criou quanto para o azureappcreatorprd.

## Variáveis
Variavel              | Tipo           | Obrigatória  | Descrição   
----------------------|----------------|--------------|--------------
project_key           |string          | Sim          | 
vault_identifier*     |string          | Sim          | Length must be shorter than 15
env                   |string          | Sim          | Allowed values are 'dev', 'hom' and 'prd'
secret_admins         |list(string)    | Não          | List of object IDs with ``all`` permissions on secrets. Defaults to azureappcreatorprd ID
secret_readers_apps   |list(string)    | Não          | List of service principals with ``get`` and ``list`` permissions on secrets. Defaults to empty list
secret_readers_groups |list(string)    | Não          | List of AD groups with ``get`` and ``list`` permissions on secrets. efaults to empty list
certificate_managers_apps   |list(string)    | Não          | List of service principals with ``management`` permissions on certificates. Defaults to empty list

*O nome do Key Vault será composto da seguinte forma: ``pf-${var.vault_identifier}-${var.env}``

## Outputs
* key_vault_id
* key_vault_name

## Exemplos
Declaração mínima:
```terraform
module "my_kv" {
  source = "./az_keyvault"

  project_key      = "myprojectkey"
  vault_identifier = "mykv"
  env              = "dev"
}
```
Declaração com grupos e apps que terão acesso a ler secrets do keyvault.
```hcl
module "my_kv" {
  source = "./az_keyvault"

  project_key           = "myprojectkey"
  vault_identifier      = "mykv"
  env                   = "dev"
  secret_readers_groups = ["AD_GROUP_1","AD_GROUP_2"]
  secret_readers_apps   = ["appname1", "appname2"]
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >1.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=2.29.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >1.0.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=2.29.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.certificate_managers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.devops_agent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.readers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.secret_admins](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_role_assignment.admin_readers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.readers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azuread_group.secret_readers](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.certificate_managers](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azuread_service_principal.secret_readers](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_area_name"></a> [area\_name](#input\_area\_name) | n/a | `string` | `""` | no |
| <a name="input_certificate_managers_apps"></a> [certificate\_managers\_apps](#input\_certificate\_managers\_apps) | List of service principals with `management` permissions on certificates. Defaults to empty list | `list(string)` | `[]` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_project_key"></a> [project\_key](#input\_project\_key) | n/a | `string` | n/a | yes |
| <a name="input_secret_admins"></a> [secret\_admins](#input\_secret\_admins) | n/a | `list(string)` | `[]` | no |
| <a name="input_secret_readers_apps"></a> [secret\_readers\_apps](#input\_secret\_readers\_apps) | List of service principals with `get` and `list` permissions on secrets. Defaults to empty list | `list(string)` | `[]` | no |
| <a name="input_secret_readers_groups"></a> [secret\_readers\_groups](#input\_secret\_readers\_groups) | List of AD groups with `get` and `list` permissions on secrets. Defaults to empty list | `list(string)` | `[]` | no |
| <a name="input_vault_identifier"></a> [vault\_identifier](#input\_vault\_identifier) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | n/a |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | n/a |
<!-- END_TF_DOCS -->