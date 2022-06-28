variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "hom", "prd"], var.env)
    error_message = "Allowed values are 'dev', 'hom' and 'prd'."
  }
  description = "Cluster environment. It will be used to tag all resources."
}

variable "clusters_region" {
  type        = string
  default     = "brazilsouth"
  description = "Azure region of the cluster"
}

variable "vault_id" {
  type        = string
  description = "Key vault to store kube-config"
}

variable "node_size" {
  type        = string
  default     = "Standard_D2_v2"
  description = "Cluster VM node size."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.21.7"
  description = "Kubernetes cluster version"
}

variable "number_nodes_per_cluster" {
  type    = number
  default = 2
}