locals {
  tags = {
    application:     [
      "environment|${var.product.environment}",
      "application|${var.product.product_name}",
    ]
  } 
}


### get preexisting groups

data "nsxt_policy_group" "lb_groups" {
  for_each = {
    for key, value in var.product.lb_groups: key => value
  }
  display_name = each.value
}

### get tag VMs
data "nsxt_policy_vm" "vms" {
   display_name = each.value
   for_each = toset(var.product.application_vms)
}



### create tags
resource "nsxt_policy_vm_tags" "application_tags" {
  depends_on = [
    data.nsxt_policy_vm.vms 
  ]
  
  instance_id = (data.nsxt_policy_vm.vms[each.key]).instance_id

  dynamic "tag" {
    for_each = local.tags.application

    content {
      scope = split("|", tag.value)[0]
      tag = split("|", tag.value)[1]
    }
  }
  for_each = toset(var.product.application_vms)
}


## application groups

## this network needs to exist because vRA has leaky networks
resource "nsxt_policy_group" "calico" {
  display_name = "app.calico.${var.product.product_name}.${var.product.environment}"
  criteria {
    ipaddress_expression {
      ip_addresses = ["10.244.0.0/16"]
    }
  }
}

resource "nsxt_policy_group" "application" {

  display_name = "app.all.${var.product.product_name}.${var.product.environment}"
  criteria {
    dynamic "condition" {
      for_each = local.tags.application
      content {
        key = "Tag"
        member_type = "VirtualMachine"
        operator = "EQUALS"
        value = condition.value
      }
    }
  }
}




resource "nsxt_policy_group" "loadbalancer" {

  display_name = "app.lb.${var.product.product_name}.${var.product.environment}"
  criteria {
    path_expression {
      member_paths = [for key, value in var.product.lb_groups: (data.nsxt_policy_group.lb_groups[key]).path]
    }
  }
}


##provider groups

# resource "nsxt_policy_group" "application_providers" {

#   display_name = "provides.${each.value}.all.${var.product.product_name}.${var.product.environment}"
#   criteria {
#     path_expression {
#       member_paths = [nsxt_policy_group.application.path]
#     }
#   }
#   for_each = toset(local.provides.app)
# }

# resource "nsxt_policy_group" "intra-app_providers" {

#   display_name = "provides.intra-app.all.${var.product.product_name}.${var.product.environment}"
#   criteria {
#     path_expression {
#       member_paths = [
#         nsxt_policy_group.application.path,
#         nsxt_policy_group.calico.path,
#         nsxt_policy_group.loadbalancer.path
#       ]
#     }
#   }
# }




# resource "nsxt_policy_group" "loadbalancer_providers" {

#   display_name = "provides.${each.value}.lb.${var.product.product_name}.${var.product.environment}"
#   criteria {
#     path_expression {
#       member_paths = [nsxt_policy_group.loadbalancer.path]
#     }
#   }
#   for_each = toset(local.provides.lb)
# }


##consumer groups


