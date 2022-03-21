variable "clusters_region" {
  type        = string
  default     = "sa-east-1"
  description = "AWS region of the cluster"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for cluster VPC"
}

variable "vpc_private_ip" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "CIDR list for private subnet"
}

variable "vpc_public_ip" {
  type        = list(string)
  default     = ["10.0.4.0/24"]
  description = "CIDR list for public subnet"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.21"
  description = "Kubernetes cluster version"
}

variable "node_size" {
  type        = string
  default     = "Standard_D2_v2"
  description = "Cluster VM node size."
}

variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "hom", "prd"], var.env)
    error_message = "Allowed values are 'dev', 'hom' and 'prd'."
  }
  description = "Cluster environment. It will be used to tag all resources."
}