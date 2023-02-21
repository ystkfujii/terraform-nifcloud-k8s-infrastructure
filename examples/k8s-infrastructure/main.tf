locals {
  west_region = "jp-west-1"
  west_az     = "west-11"

  instance_key_name = "deployerkey"

  instance_type_bastion = "e-medium"
  instance_type_egress  = "e-medium"
  instance_type_cp      = "e-medium"
  instance_type_wk      = "e-medium"

  instance_count_cp = 3
  instance_count_wk = 2
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
resource "nifcloud_elastic_ip" "bastion" {
  ip_type           = false
  availability_zone = local.west_az
  description       = "bastion"
}
resource "nifcloud_elastic_ip" "egress" {
  ip_type           = false
  availability_zone = local.west_az
  description       = "egress"
}

#####
# Module
#

# k8s cluster
module "k8s_cluster" {
  source = "../../"

  availability_zone = local.west_az

  instance_key_name = local.instance_key_name

  elasticip_bastion = nifcloud_elastic_ip.bastion.public_ip
  elasticip_egress  = nifcloud_elastic_ip.egress.public_ip

  instance_count_cp = local.instance_count_cp
  instance_count_wk = local.instance_count_wk

  instance_type_bastion = local.instance_type_bastion
  instance_type_egress  = local.instance_type_egress
  instance_type_cp      = local.instance_type_cp
  instance_type_wk      = local.instance_type_wk
}
