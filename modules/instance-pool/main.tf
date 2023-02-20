#####
# Security Group 
#
resource "nifcloud_security_group" "this" {
  group_name        = "${var.az_short_name}${var.prefix}${var.role}"
  description       = "${var.az_short_name} ${var.prefix} ${var.role}"
  availability_zone = var.availability_zone
}

#####
# Module : instance
#
module "instance_pool" {
  source = "../instance"
  count = var.instance_count

  availability_zone   = var.availability_zone
  instance_id         = "${var.az_short_name}${var.prefix}${var.role}${count.index  + 1}"
  security_group_name = nifcloud_security_group.this.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type
  accounting_type     = var.accounting_type

  interface_private   = {
    ip_address = "${var.private_network_3octet}.${count.index + 1}/${var.private_network_subnet}"
    network_id = var.private_network_id 
  }
}

#####
# LB
#
resource "nifcloud_load_balancer" "this" {
  count = var.lb_portforward == null ? 0 : 1

  load_balancer_name = "${var.az_short_name}${var.prefix}${var.role}"
  accounting_type = var.accounting_type
  balancing_type = 1 // Round-Robin
  load_balancer_port = var.lb_portforward.from
  instance_port = var.lb_portforward.to
  instances = module.instance_pool[*].instance_id
}

