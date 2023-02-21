output "instance_info" {
  description = "Instance infomation in instance-pool"
  value = {
    instance_id = module.instance_pool[*].instance_id
    unique_id   = module.instance_pool[*].unique_id
    private_ip  = module.instance_pool[*].private_ip
    public_ip   = module.instance_pool[*].public_ip
  }
}

output "lb_dns_name" {
  description = "Public IP address of LB connected to the instance-pool"
  value       = var.lb_portforward == null ? "" : nifcloud_load_balancer.this[0].dns_name
}

output "security_group_name" {
  description = "Security group name applied to instance"
  value       = nifcloud_security_group.this.group_name
}