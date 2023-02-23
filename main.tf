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

# control plane
module "control_plane" {
  source = "./modules/instance-pool"

  availability_zone = var.availability_zone

  az_short_name = local.az_short_name
  prefix        = var.prefix
  role          = local.role_control_plane

  instance_key_name = var.instance_key_name
  instance_count    = var.instance_count_cp
  instance_type     = var.instance_type_cp

  private_network_id = nifcloud_private_lan.this.network_id

  private_network_subnet = var.private_network_subnet
  private_network_prefix = local.private_network_prefix
  ip_start               = local.ip_start_control_plane

  lb_portforward = {
    from = 6443
    to   = 6443
  }

  depends_on = [
    nifcloud_private_lan.this,
  ]
}

# worker
module "worker" {
  source = "./modules/instance-pool"

  availability_zone = var.availability_zone

  az_short_name = local.az_short_name
  prefix        = var.prefix
  role          = local.role_worker

  instance_key_name = var.instance_key_name
  instance_count    = var.instance_count_wk
  instance_type     = var.instance_type_wk

  private_network_id = nifcloud_private_lan.this.network_id

  private_network_subnet = var.private_network_subnet
  private_network_prefix = local.private_network_prefix
  ip_start               = local.ip_start_worker

  depends_on = [
    nifcloud_private_lan.this,
  ]
}

#####
# Security Group Rule
#

# ssh
resource "nifcloud_security_group_rule" "ssh_from_bastion" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
    module.worker.security_group_name,
    module.control_plane.security_group_name,
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
    module.control_plane.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubectl
  to_port                    = local.port_kubectl
  protocol                   = "TCP"
  source_security_group_name = module.worker.security_group_name
}

resource "nifcloud_security_group_rule" "kubectl_from_bastion" {
  security_group_names = [
    module.control_plane.security_group_name,
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
    module.control_plane.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = module.worker.security_group_name
}

resource "nifcloud_security_group_rule" "kubelet_from_control_plane" {
  security_group_names = [
    module.worker.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = module.control_plane.security_group_name
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
  source_security_group_name = module.worker.security_group_name
}

resource "nifcloud_security_group_rule" "squid_from_control_plane" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = module.control_plane.security_group_name
}
