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

*O nome do Key Vault será composto da seguinte forma: ``azdo-${var.vault_identifier}-${var.env}``

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

