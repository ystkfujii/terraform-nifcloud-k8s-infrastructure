
locals {
  private_network_cidr = "${var.private_network_subnet}/${var.private_network_prefix}"
}

#####
# Security Group
#
resource "nifcloud_security_group" "this" {
  group_name        = "${var.az_short_name}${var.prefix}${var.role}"
  description       = "${var.az_short_name} ${var.prefix} ${var.role}"
  availability_zone = var.availability_zone
}

#####
# Module
#
module "instance_pool" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.2"

  count = var.instance_count

  availability_zone   = var.availability_zone
  instance_name       = "${var.az_short_name}${var.prefix}${var.role}${format("%02d", count.index + 1)}"
  security_group_name = nifcloud_security_group.this.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type
  accounting_type     = var.accounting_type

  interface_private = {
    ip_address = "${cidrhost(local.private_network_cidr, (var.ip_start + count.index + 1))}/${var.private_network_prefix}"
    network_id = var.private_network_id
  }

  depends_on = [
    nifcloud_security_group.this,
  ]
}

#####
# LB
#
resource "nifcloud_load_balancer" "this" {
  count = var.lb_portforward == null ? 0 : 1

  load_balancer_name = "${var.az_short_name}${var.prefix}${var.role}"
  accounting_type    = var.accounting_type
  balancing_type     = 1 // Round-Robin
  load_balancer_port = var.lb_portforward.from
  instance_port      = var.lb_portforward.to
  instances          = module.instance_pool[*].instance_id
}

