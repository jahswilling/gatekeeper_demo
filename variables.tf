variable "name" {
  type        = string
  description = "Name of release"
  default     = "gatekeeper"
}

variable "namespace" {
  type        = string
  description = "Namespace name to deploy helm release"
  default     = "gatekeeper-system"
}

variable "repository" {
  type        = string
  description = "Repository to install the chart from"
  default     = "https://open-policy-agent.github.io/gatekeeper/charts"
}

variable "chart_version" {
  type        = string
  description = "Helm chart to release"
  default     = "3.18.2"
}

variable "serviceaccount" {
  type        = string
  description = "Serviceaccount name"
  default     = "gatekeeper"
}

variable "cluster_name" {
  type        = string
  description = "Name of EKS cluster"
}