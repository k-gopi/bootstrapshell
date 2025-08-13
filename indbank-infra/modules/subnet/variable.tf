variable "subnets" {
  type = map(object({ cidr = string }))
}
variable "vnet_name" {}
variable "rg_name" {}
