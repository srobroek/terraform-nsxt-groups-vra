variable "product" {
  type = object({
      environment = string      
      product_name = string 
      enabled = bool
      application_vms = list(string)
      lb_groups = list(string)
    })

}