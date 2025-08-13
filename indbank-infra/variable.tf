variable "project" {}
variable "environment" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "location" {}
variable "rg_name" {}
variable "key_vault_name" {}

variable "backend_rg" {}
variable "backend_storage_account" {}
variable "backend_container" {}

variable "vnet_name" {}
variable "vnet_address_space" {}

variable "subnets" {
  type = map(object({ cidr = string }))
}

variable "vm_sizes" {
  type = map(string)
}

variable "disk_types" {
  type = map(string)
}

variable "disk_sizes" {
  type = map(number)
}
