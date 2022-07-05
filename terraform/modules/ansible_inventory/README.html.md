<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.inventory_file](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.run_ansible](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_vars"></a> [extra\_vars](#input\_extra\_vars) | Extra Parameters to ansible inventory | `map(any)` | `{}` | no |
| <a name="input_galaxy_install_collections"></a> [galaxy\_install\_collections](#input\_galaxy\_install\_collections) | n/a | `list(string)` | `[]` | no |
| <a name="input_galaxy_install_roles"></a> [galaxy\_install\_roles](#input\_galaxy\_install\_roles) | n/a | `list(string)` | `[]` | no |
| <a name="input_galaxy_requirements"></a> [galaxy\_requirements](#input\_galaxy\_requirements) | n/a | `string` | `""` | no |
| <a name="input_hosts"></a> [hosts](#input\_hosts) | Hosts List | `list(any)` | n/a | yes |
| <a name="input_inventory_filename"></a> [inventory\_filename](#input\_inventory\_filename) | n/a | `string` | `"ansible-inventory"` | no |
| <a name="input_python_interpreter"></a> [python\_interpreter](#input\_python\_interpreter) | n/a | `string` | `"/usr/bin/python3"` | no |
| <a name="input_run_playbook"></a> [run\_playbook](#input\_run\_playbook) | Playbook to run | `string` | `""` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Triggers to run ansible | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host_ip_list"></a> [host\_ip\_list](#output\_host\_ip\_list) | n/a |
| <a name="output_inventory"></a> [inventory](#output\_inventory) | n/a |
<!-- END_TF_DOCS -->