variable "azure_cluster_regions" {
  type        = list(string)
  default     = ["brazilsouth", "westus"]
  description = "Region of each AKS cluster"
}

variable "aws_cluster_region" {
  type        = string
  default     = ""
  description = "Region of each EKS cluster"
}