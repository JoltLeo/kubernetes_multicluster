variable "project_key" {type = string}
variable "vault_identifier" {
    type = string
    validation {
      condition     = length(var.vault_identifier) < 16
      error_message = "The vault_identifier length must be shorter than 15."
    }    
}
variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "hom", "prd"], var.env)
    error_message = "Allowed values are 'dev', 'hom' and 'prd'."
  }
}

variable "secret_admins" {
    type = list(string)
    default = [""]
}
variable "area_name" {
    type    = string
    default = ""
}
variable "secret_readers_apps" {
    type        = list(string)
    default     = []
    description = "List of service principals with ``get`` and ``list`` permissions on secrets. Defaults to empty list"
}
variable "certificate_managers_apps" {
    type        = list(string)
    default     = []
    description = "List of service principals with ``management`` permissions on certificates. Defaults to empty list"
}
variable "secret_readers_groups" {
    type        = list(string)
    default     = []
    description = "List of AD groups with ``get`` and ``list`` permissions on secrets. Defaults to empty list"
}
