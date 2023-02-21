resource "nifcloud_private_lan" "this" {
  private_lan_name  = "${var.prefix}lan"
  availability_zone = var.availability_zone
  cidr_block        = var.private_network_cidr
  accounting_type   = var.accounting_type
}

resource "nifcloud_dhcp_config" "this" {
  ipaddress_pool {
    ipaddress_pool_start = var.dhcp_config.ipaddress_pool_start
    ipaddress_pool_stop  = var.dhcp_config.ipaddress_pool_stop
  }
}

resource "nifcloud_security_group" "this" {
  group_name        = "${var.prefix}router"
  availability_zone = var.availability_zone
}

resource "nifcloud_router" "this" {
  name              = "${var.prefix}router"
  availability_zone = var.availability_zone
  security_group    = nifcloud_security_group.this.group_name
  accounting_type   = var.accounting_type
  type              = var.router_type

  network_interface {
    network_name   = nifcloud_private_lan.this.private_lan_name
    ip_address     = var.router_ip_address
    dhcp           = true
    dhcp_config_id = nifcloud_dhcp_config.this.id
  }
}
