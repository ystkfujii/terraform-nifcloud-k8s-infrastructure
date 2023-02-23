output "control_plane_lb" {
  description = "The DNS name of LB for control plane"
  value       = module.control_plane.lb_dns_name
}

output "security_group_name" {
  description = "The security group used in the cluster"
  value = {
    bastion       = nifcloud_security_group.bastion.group_name,
    egress        = nifcloud_security_group.egress.group_name,
    control_plane = module.control_plane.security_group_name,
    worker        = module.worker.security_group_name,
  }
}

output "worker_info" {
  description = "The worker infomation in cluster"
  value       = module.worker.instance_info
}

output "control_plane_info" {
  description = "The control plane infomation in cluster"
  value       = module.control_plane.instance_info
}
