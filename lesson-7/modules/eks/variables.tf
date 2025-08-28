variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where to create the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where to create the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Configuration for EKS node groups"
  type = map(object({
    desired_capacity = number
    max_capacity     = number
    min_capacity     = number
    instance_types   = list(string)
    disk_size        = number
  }))
  default = {
    main = {
      desired_capacity = 2
      max_capacity     = 6
      min_capacity     = 2
      instance_types   = ["t3.medium"]
      disk_size        = 20
    }
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}