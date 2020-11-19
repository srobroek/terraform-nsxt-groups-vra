output "groups" {
  value = {
    # provider = nsxt_policy_group.application_providers
    vra = nsxt_policy_group.application
    lb = nsxt_policy_group.loadbalancer
    calico = nsxt_policy_group.calico
    # intra-app = nsxt_policy_group.intra-app_providers

  }    
}