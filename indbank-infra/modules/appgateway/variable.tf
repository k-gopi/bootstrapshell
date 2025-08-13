variable "rg_name" {}
variable "location" {}
variable "subnet_id" {}
variable "backend_vms" {
  type = list(string)
}
