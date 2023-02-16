variable "project_name" {
  type = string
  default = "example"
}

variable "tap_profile" {
  type = string
  default = "iterate"
}

variable "tanzunet_username" {
  type = string
}

variable "tanzunet_password" {
  type = string
  sensitive = true
}

variable "gitops_repo_url" {
  type = string
  default = "https://github.com/cdelashmutt-pivotal/terraform-accelerator"
}

variable "gitops_repo_branch" {
  type = string
  default = "dev"
}

variable "gitops_repo_subPath" {
  type = string
  default = "cluster"
}

variable "dns_parent_zone_rg" {
  type = string
  default = "dns"
}

variable "dns_parent_zone_name" {
  type = string
  default = "azure.grogscave.net"
}

variable "view_cluster_domain" {
  type = string
  default = "central.azure.grogscave.net"
}