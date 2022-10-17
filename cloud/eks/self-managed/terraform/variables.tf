variable "cluster_id" {
  type        = string
  description = "The prefix of your EKS cluster name."
  default     = "hcp-learn"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region your resources are created in."
  default     = "us-east-1"
}