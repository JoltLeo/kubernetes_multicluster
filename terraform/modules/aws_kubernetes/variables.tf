variable "cluster_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region of the cluster"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for cluster VPC"
}

variable "vpc_private_ip" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "CIDR list for private subnet"
}

variable "vpc_public_ip" {
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  description = "CIDR list for public subnet"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.22.6"
  description = "Kubernetes cluster version"
}

variable "node_size" {
  type        = string
  default     = "t2.large"
  description = "Cluster VM node size."
}

variable "vault_id" {
  type        = string
  description = "Key vault to store kube-config"
}

variable "number_nodes_per_cluster" {
  type    = number
  default = 2
}

variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "hom", "prd"], var.env)
    error_message = "Allowed values are 'dev', 'hom' and 'prd'."
  }
  description = "Cluster environment. It will be used to tag all resources."
}