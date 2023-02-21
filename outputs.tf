output "controle_plane_lb" {
  description = "The DNS name of LB for controle plane"
  value       = module.controle_plane.lb_dns_name
}

output "security_group_name" {
  description = "The security group used in the cluster"
  value = {
    bastion        = nifcloud_security_group.bastion.group_name,
    egress         = nifcloud_security_group.egress.group_name,
    controle_plane = module.controle_plane.security_group_name,
    worker         = module.worker.security_group_name,
  }
}

output "worker_instance_info" {
  description = "The Worker infomation in cluster"
  value       = module.worker.instance_info
}
