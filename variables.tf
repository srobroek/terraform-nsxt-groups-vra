
variable "environment" {
  type = string
  default = "prod"
}
variable "product" {
  type = string 
  default = "vra"
}

variable "application_vms" {
  type = list(string)
}

variable "lb_groups" {
  type = list(string)
}
