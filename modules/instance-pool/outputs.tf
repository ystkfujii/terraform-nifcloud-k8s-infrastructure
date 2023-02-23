output "instance_info" {
  description = "Instance infomation in instance-pool"
  value = { for v in module.instance_pool : v.instance_id => {
    unique_id  = v.unique_id,
    private_ip = v.private_ip,
    public_ip  = v.public_ip,
  } }
}

output "lb_dns_name" {
  description = "Public IP address of LB connected to the instance-pool"
  value       = var.lb_portforward == null ? "" : nifcloud_load_balancer.this[0].dns_name
}

output "security_group_name" {
  description = "Security group name applied to instance"
  value       = nifcloud_security_group.this.group_name
}