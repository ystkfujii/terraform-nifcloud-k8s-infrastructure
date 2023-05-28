locals {
  west_region = "jp-west-1"
  west_az     = "west-11"

  instance_key_name = "deployerkey"

  instance_type_bn = "e-medium"
  instance_type_px = "e-medium"
  instance_type_cp = "e-medium"
  instance_type_wk = "e-medium"

  private_network_cidr = "192.168.10.0/24"
  instances_cp = {
    "cp01" : { private_ip : "192.168.10.13/24" }
  }
  instances_wk = {
    "wk01" : { private_ip : "192.168.10.23/24" }
    "wk02" : { private_ip : "192.168.10.24/24" }
  }

  private_ip_bn = "192.168.10.12/24"
  private_ip_px = "192.168.10.13/24"
}

#####
# Provider
#
provider "nifcloud" {
  region = local.west_region
}

#####
# Elastic IP
#

# elastic ip
resource "nifcloud_elastic_ip" "bn" {
  ip_type           = false
  availability_zone = local.west_az
  description       = "bastion"
}
resource "nifcloud_elastic_ip" "px" {
  ip_type           = false
  availability_zone = local.west_az
  description       = "egress"
}

#####
# Module
#
module "k8s_infrastructure" {
  source = "../../"

  availability_zone = local.west_az
  prefix            = "dev"

  private_network_cidr = local.private_network_cidr

  instance_key_name = local.instance_key_name
  instances_cp      = local.instances_cp
  instances_wk      = local.instances_wk

  elasticip_bn = nifcloud_elastic_ip.bn.public_ip
  elasticip_px = nifcloud_elastic_ip.px.public_ip

  instance_type_bn = local.instance_type_bn
  instance_type_px = local.instance_type_px
  instance_type_cp = local.instance_type_cp
  instance_type_wk = local.instance_type_wk

  private_ip_bn = local.private_ip_bn
  private_ip_px = local.private_ip_px
}
