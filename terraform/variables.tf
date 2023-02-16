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