output "controle_plnae_lb" {
  description = "The DNS name of LB for controle plane"
  value = module.controle_plane.lb_dns_name
}

output "security_group_name" {
  value = {
    bastion = nifcloud_security_group.bastion.group_name,
    egress = nifcloud_security_group.egress.group_name,
    controle_plane = module.controle_plane.security_group_name,
    worker = module.worker.security_group_name,
  }
}

output "worker_instance_info" {
  description = "worker infomation in cluster"
  value       = {
    instance_id = module.worker[*].instance_id
    unique_id = module.worker[*].unique_id
    private_ip = module.worker[*].private_ip
    public_ip = module.worker[*].public_ip
  }
}
