provider "nsxt" {
  allow_unverified_ssl      = var.nsxt_cluster_allow_unverified_ssl
  max_retries               = 10
  retry_min_delay           = 500
  retry_max_delay           = 5000
  retry_on_status_codes     = [429]
  username                  = var.nsxt_cluster_username
  password                  = var.nsxt_cluster_password
  host                      = var.nsxt_cluster_fqdn
}

locals {
  tags = {
    application:     [
      "environment|${var.environment}",
      "application|${var.product}",
    ]
  } 
}


### get preexisting groups

data "nsxt_policy_group" "lb_groups" {
  for_each = {
    for key, value in var.lb_groups: key => value
  }
  display_name = each.value
}

### get tag VMs
data "nsxt_policy_vm" "vms" {
   display_name = each.value
   for_each = toset(var.application_vms)
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
  for_each = toset(var.application_vms)
}


## application groups

## this network needs to exist because vRA has leaky networks
resource "nsxt_policy_group" "calico" {
  display_name = "app.calico.${var.product}.${var.environment}"
  criteria {
    ipaddress_expression {
      ip_addresses = ["10.244.0.0/16"]
    }
  }
}

resource "nsxt_policy_group" "application" {

  display_name = "app.all.${var.product}.${var.environment}"
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

  display_name = "app.lb.${var.product}.${var.environment}"
  criteria {
    path_expression {
      member_paths = [for key, value in var.lb_groups: (data.nsxt_policy_group.lb_groups[key]).path]
    }
  }
}


