locals {
  # e.g. east-11 is 11
  az_num = reverse(split("-", var.availability_zone))[0]
  # e.g. east-11 is e11
  az_short_name = "${substr(reverse(split("-", var.availability_zone))[1], 0, 1)}${local.az_num}"

  role_control_plane = "cp"
  role_worker        = "wk"

  private_network_prefix = 24
  private_network_cidr   = "${var.private_network_subnet}/${local.private_network_prefix}"

  egress_private_ip  = "${cidrhost(local.private_network_cidr, 1)}/${local.private_network_prefix}"
  bastion_private_ip = "${cidrhost(local.private_network_cidr, 2)}/${local.private_network_prefix}"

  # Nubmer of 4th octet begins
  ip_start_control_plane = 64
  ip_start_worker        = 32

  # Port used by the protocol
  port_ssh     = 22
  port_squid   = 3128
  port_kubectl = 6443
  port_kubelet = 10250
}

resource "nifcloud_private_lan" "this" {
  private_lan_name  = "${var.prefix}lan"
  availability_zone = var.availability_zone
  cidr_block        = local.private_network_cidr
  accounting_type   = var.accounting_type
}

#####
# Security Group
#
resource "nifcloud_security_group" "bastion" {
  group_name        = "${var.prefix}bastion"
  description       = "${var.prefix} bastion"
  availability_zone = var.availability_zone
}
resource "nifcloud_security_group" "egress" {
  group_name        = "${var.prefix}egress"
  description       = "${var.prefix} egress"
  availability_zone = var.availability_zone
}
resource "nifcloud_security_group" "cp" {
  group_name        = "${var.prefix}cp"
  description       = "${var.prefix} control plane"
  availability_zone = var.availability_zone
}
resource "nifcloud_security_group" "wk" {
  group_name        = "${var.prefix}wk"
  description       = "${var.prefix} worker"
  availability_zone = var.availability_zone
}

#####
# LB
#
resource "nifcloud_load_balancer" "this" {

  load_balancer_name = "${local.az_short_name}${var.prefix}cp"
  accounting_type    = var.accounting_type
  balancing_type     = 1 // Round-Robin
  load_balancer_port = 6443
  instance_port      = 6443
  instances          = module.wk[*].instance_id
}

#####
# Module
#

module "egress" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.2"

  availability_zone   = var.availability_zone
  instance_name       = "${local.az_short_name}${var.prefix}egress"
  security_group_name = nifcloud_security_group.egress.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_egress
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_egress
  interface_private = {
    ip_address = local.egress_private_ip
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.egress,
  ]
}

module "bastion" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.2"

  availability_zone   = var.availability_zone
  instance_name       = "${local.az_short_name}${var.prefix}bastion"
  security_group_name = nifcloud_security_group.bastion.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_bastion
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_bastion
  interface_private = {
    ip_address = local.bastion_private_ip
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.bastion,
  ]
}

module "cp" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.2"

  count = var.instance_count_cp

  availability_zone   = var.availability_zone
  instance_name       = "${local.az_short_name}${var.prefix}cp${format("%02d", count.index + 1)}"
  security_group_name = nifcloud_security_group.cp.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_bastion
  accounting_type     = var.accounting_type
  interface_private = {
    ip_address = "${cidrhost(local.private_network_cidr, (local.ip_start_control_plane + count.index + 1))}/${local.private_network_prefix}"
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.cp,
  ]
}

module "wk" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.2"

  count = var.instance_count_wk

  availability_zone   = var.availability_zone
  instance_name       = "${local.az_short_name}${var.prefix}cp${format("%02d", count.index + 1)}"
  security_group_name = nifcloud_security_group.wk.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_bastion
  accounting_type     = var.accounting_type
  interface_private = {
    ip_address = "${cidrhost(local.private_network_cidr, (local.ip_start_worker + count.index + 1))}/${local.private_network_prefix}"
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.wk,
  ]
}


#####
# Security Group Rule
#

# ssh
resource "nifcloud_security_group_rule" "ssh_from_bastion" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
    nifcloud_security_group.wk.group_name,
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_ssh
  to_port                    = local.port_ssh
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bastion.group_name
}

# kubectl
resource "nifcloud_security_group_rule" "kubectl_from_worker" {
  security_group_names = [
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubectl
  to_port                    = local.port_kubectl
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.wk.group_name
}

resource "nifcloud_security_group_rule" "kubectl_from_bastion" {
  security_group_names = [
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubectl
  to_port                    = local.port_kubectl
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bastion.group_name
}

# kubelet
resource "nifcloud_security_group_rule" "kubelet_from_worker" {
  security_group_names = [
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.wk.group_name
}

resource "nifcloud_security_group_rule" "kubelet_from_control_plane" {
  security_group_names = [
    nifcloud_security_group.wk.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.cp.group_name
}

# squid
resource "nifcloud_security_group_rule" "squid_from_bastion" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bastion.group_name
}

resource "nifcloud_security_group_rule" "squid_from_worker" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.wk.group_name
}

resource "nifcloud_security_group_rule" "squid_from_control_plane" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.cp.group_name
}
