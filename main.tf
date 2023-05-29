locals {
  # e.g. east-11 is 11
  az_num = reverse(split("-", var.availability_zone))[0]
  # e.g. east-11 is e11
  az_short_name = "${substr(reverse(split("-", var.availability_zone))[1], 0, 1)}${local.az_num}"

  # Port used by the protocol
  port_ssh     = 22
  port_squid   = 3128
  port_kubectl = 6443
  port_kubelet = 10250

  extra_userdata = templatefile("${path.module}/templates/extra_userdata.tftpl", {})
}

resource "nifcloud_private_lan" "this" {
  private_lan_name  = "${var.prefix}lan"
  availability_zone = var.availability_zone
  cidr_block        = var.private_network_cidr
  accounting_type   = var.accounting_type
}

#####
# Security Group
#
resource "nifcloud_security_group" "bn" {
  group_name        = "${var.prefix}bn"
  description       = "${var.prefix} bastion"
  availability_zone = var.availability_zone
}
resource "nifcloud_security_group" "px" {
  group_name        = "${var.prefix}px"
  description       = "${var.prefix} proxy"
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

  load_balancer_name = "${var.prefix}${local.az_short_name}cp"
  accounting_type    = var.accounting_type
  balancing_type     = 1 // Round-Robin
  load_balancer_port = 6443
  instance_port      = 6443
  instances          = [for v in module.cp : v.instance_id]
}

#####
# Module
#

module "px" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.5"

  availability_zone   = var.availability_zone
  instance_name       = "${var.prefix}${local.az_short_name}px01"
  security_group_name = nifcloud_security_group.px.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_px
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_px
  interface_private = {
    ip_address = var.private_ip_px
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.px,
  ]
}

module "bn" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.5"

  availability_zone   = var.availability_zone
  instance_name       = "${var.prefix}${local.az_short_name}bn01"
  security_group_name = nifcloud_security_group.bn.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_bn
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_bn
  interface_private = {
    ip_address = var.private_ip_bn
    network_id = nifcloud_private_lan.this.network_id
  }

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.px,
  ]
}

module "cp" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.5"

  for_each = var.instances_cp

  availability_zone   = var.availability_zone
  instance_name       = "${var.prefix}${local.az_short_name}${each.key}"
  security_group_name = nifcloud_security_group.cp.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_cp
  accounting_type     = var.accounting_type
  interface_private = {
    ip_address = each.value.private_ip
    network_id = nifcloud_private_lan.this.network_id
  }

  extra_userdata = local.extra_userdata

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.cp,
  ]
}

module "wk" {
  source  = "ystkfujii/instance/nifcloud"
  version = "0.0.5"

  for_each = var.instances_wk

  availability_zone   = var.availability_zone
  instance_name       = "${var.prefix}${local.az_short_name}${each.key}"
  security_group_name = nifcloud_security_group.wk.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_wk
  accounting_type     = var.accounting_type
  interface_private = {
    ip_address = each.value.private_ip
    network_id = nifcloud_private_lan.this.network_id
  }

  extra_userdata = local.extra_userdata

  depends_on = [
    nifcloud_private_lan.this,
    nifcloud_security_group.wk,
  ]
}


#####
# Security Group Rule
#

# ssh
resource "nifcloud_security_group_rule" "ssh_from_bn" {
  security_group_names = [
    nifcloud_security_group.px.group_name,
    nifcloud_security_group.wk.group_name,
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_ssh
  to_port                    = local.port_ssh
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bn.group_name
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

resource "nifcloud_security_group_rule" "kubectl_from_bn" {
  security_group_names = [
    nifcloud_security_group.cp.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubectl
  to_port                    = local.port_kubectl
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bn.group_name
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
resource "nifcloud_security_group_rule" "squid_from_bn" {
  security_group_names = [
    nifcloud_security_group.px.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.bn.group_name
}

resource "nifcloud_security_group_rule" "squid_from_worker" {
  security_group_names = [
    nifcloud_security_group.px.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.wk.group_name
}

resource "nifcloud_security_group_rule" "squid_from_control_plane" {
  security_group_names = [
    nifcloud_security_group.px.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = nifcloud_security_group.cp.group_name
}
