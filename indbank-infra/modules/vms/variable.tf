variable "vm_name" {}
variable "location" {}
variable "rg_name" {}
variable "subnet_id" {}
variable "vm_size" {}
variable "disk_type" {}
variable "disk_size_gb" {}
variable "username" {}
variable "password" {}
variable "public_ip" {
  type    = bool
  default = false
}
