data "nifcloud_image" "ubuntu" {
  image_name = var.ubuntu_image_name
}

resource "nifcloud_instance" "this" {

  instance_id       = var.instance_id
  availability_zone = var.availability_zone
  image_id          = data.nifcloud_image.ubuntu.image_id
  key_name          = var.key_name
  security_group    = var.security_group_name
  instance_type     = var.instance_type
  accounting_type   = var.accounting_type

  network_interface {
    network_id = "net-COMMON_GLOBAL"
    ip_address = var.public_ip_address
  }

  network_interface {
    network_id = var.interface_private == null ? "net-COMMON_PRIVATE" : var.interface_private.network_id
    ip_address = var.interface_private == null ? null : "static"
  }

  user_data = var.interface_private == null ? null : templatefile("${path.module}/scripts/userdata.sh", {
    private_ip_address = var.interface_private.ip_address
  })
}

