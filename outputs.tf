output "control_plane_lb" {
  description = "The DNS name of LB for control plane"
  value       = nifcloud_load_balancer.this.dns_name
}

output "security_group_name" {
  description = "The security group used in the cluster"
  value = {
    bastion       = nifcloud_security_group.bastion.group_name,
    egress        = nifcloud_security_group.egress.group_name,
    control_plane = nifcloud_security_group.cp.group_name,
    worker        = nifcloud_security_group.wk.group_name,
  }
}

output "private_network_id" {
  description = "The private network used in the cluster"
  value       = nifcloud_private_lan.this.id
}

output "egress_info" {
  description = "The egress information in cluster"
  value = { (module.egress.instance_id) : {
    unique_id  = module.egress.unique_id,
    private_ip = module.egress.private_ip,
  } }
}

output "bastion_info" {
  description = "The basion information in cluster"
  value = { (module.bastion.instance_id) : {
    unique_id  = module.bastion.unique_id,
    private_ip = module.bastion.private_ip,
  } }
}

output "worker_info" {
  description = "The worker information in cluster"
  value = { for v in module.wk : v.instance_id => {
    unique_id  = v.unique_id,
    private_ip = v.private_ip,
  } }
}

output "control_plane_info" {
  description = "The control plane information in cluster"
  value = { for v in module.cp : v.instance_id => {
    unique_id  = v.unique_id,
    private_ip = v.private_ip,
  } }
}
