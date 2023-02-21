locals {
  # e.g. east-11 is 11
  az_num = reverse(split("-", var.availability_zone))[0]
  # e.g. east-11 is e11
  az_short_name = "${substr(reverse(split("-", var.availability_zone))[1], 0, 1)}${local.az_num}"

  role_controle_plane = "cp"
  role_worker         = "wk"

  private_network_subnet = "16"
  private_network_cidr   = "192.168.0.0/${local.private_network_subnet}"
  # instance
  egress_private_ip  = "192.168.0.1/${local.private_network_subnet}"
  bastion_private_ip = "192.168.0.2/${local.private_network_subnet}"
  # router
  router_private_ip = "192.168.100.1"

  dhcp_config = {
    ipaddress_pool_start = "192.168.100.2"
    ipaddress_pool_stop  = "192.168.100.255"
  }

  private_network_3octet_cp = "192.168.1"
  private_network_3octet_wk = "192.168.2"

  port_ssh     = 22
  port_squid   = 3128
  port_kubectl = 6443
  port_kubelet = 10250
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

# private network
module "private_network" {
  source = "./modules/private-network"

  availability_zone = var.availability_zone
  prefix            = var.prefix

  private_network_cidr = local.private_network_cidr
  router_ip_address    = local.router_private_ip
  dhcp_config          = local.dhcp_config
}

# egress
module "instance" {
  source = "./modules/instance"

  availability_zone   = var.availability_zone
  instance_id         = "${local.az_short_name}${var.prefix}egress"
  security_group_name = nifcloud_security_group.egress.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_egress
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_egress
  interface_private = {
    ip_address = local.egress_private_ip
    network_id = module.private_network.network_id
  }

  depends_on = [
    module.private_network,
  ]
}

# bastion
module "bastion" {
  source = "./modules/instance"

  availability_zone   = var.availability_zone
  instance_id         = "${local.az_short_name}${var.prefix}bastion"
  security_group_name = nifcloud_security_group.bastion.group_name
  key_name            = var.instance_key_name
  instance_type       = var.instance_type_bastion
  accounting_type     = var.accounting_type

  public_ip_address = var.elasticip_bastion
  interface_private = {
    ip_address = local.bastion_private_ip
    network_id = module.private_network.network_id
  }

  depends_on = [
    module.private_network,
  ]
}

# controle plane
module "controle_plane" {
  source = "./modules/instance-pool"

  availability_zone = var.availability_zone

  az_short_name = local.az_short_name
  prefix        = var.prefix
  role          = local.role_controle_plane

  instance_key_name = var.instance_key_name
  instance_count    = var.instance_count_cp
  instance_type     = var.instance_type_cp

  private_network_id     = module.private_network.network_id
  private_network_subnet = local.private_network_subnet
  private_network_3octet = local.private_network_3octet_cp

  lb_portforward = {
    from = 6443
    to   = 6443
  }

  depends_on = [
    module.private_network,
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

  private_network_id     = module.private_network.network_id
  private_network_subnet = local.private_network_subnet
  private_network_3octet = local.private_network_3octet_wk

  depends_on = [
    module.private_network,
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
    module.controle_plane.security_group_name,
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
    module.controle_plane.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubectl
  to_port                    = local.port_kubectl
  protocol                   = "TCP"
  source_security_group_name = module.worker.security_group_name
}

resource "nifcloud_security_group_rule" "kubectl_from_bastion" {
  security_group_names = [
    module.controle_plane.security_group_name,
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
    module.controle_plane.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = module.worker.security_group_name
}

resource "nifcloud_security_group_rule" "kubelet_from_controle_plane" {
  security_group_names = [
    module.worker.security_group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_kubelet
  to_port                    = local.port_kubelet
  protocol                   = "TCP"
  source_security_group_name = module.controle_plane.security_group_name
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

resource "nifcloud_security_group_rule" "squid_from_controle_plane" {
  security_group_names = [
    nifcloud_security_group.egress.group_name,
  ]
  type                       = "IN"
  from_port                  = local.port_squid
  to_port                    = local.port_squid
  protocol                   = "TCP"
  source_security_group_name = module.controle_plane.security_group_name
}
