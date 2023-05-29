# terraform-nifcloud-k8s-infrastructure

This Terraform module will provision the nifcloud infrastructure for a kubernetes cluster.
To build a kubernetes cluster, you will need to use a another tool such as [kubespray.io](https://kubespray.io/).

## Usage

There are examples included in the examples folder but simple usage is as follows:

```hcl
locals {
  instance_key_name     = "deployerkey"

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

provider "nifcloud" {
  region     = "jp-west-1"
}

# elastic ip
resource "nifcloud_elastic_ip" "bn" {
  ip_type           = false
  availability_zone = "west-11"
}
resource "nifcloud_elastic_ip" "px" {
  ip_type           = false
  availability_zone = "west-11"
}

# k8s infrastructure
module "k8s_infrastructure" {
  source  = "ystkfujii/k8s-infrastructure/nifcloud"

  availability_zone = "west-11"

  private_network_cidr = local.private_network_cidr

  instance_key_name = local.instance_key_name
  instances_cp      = local.instances_cp
  instances_wk      = local.instances_wk

  elasticip_bn = nifcloud_elastic_ip.bn.public_ip
  elasticip_px = nifcloud_elastic_ip.px.public_ip

  private_ip_bn = local.private_ip_bn
  private_ip_px = local.private_ip_px
}
```

Then perform the following commands on the root folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

## Inputs


| Name                 | Description                                                 | Type                | Default           |
| -------------------- | ----------------------------------------------------------- | ------------------- | ----------------- |
| availability_zone    | The availability zone                                       | string              |                   |
| prefix               | Prefix to include in the name of the resource to be created | string              | `001`             |
| private_network_cidr | The cidr of private network                                 | string              | `192.168.10.0/24` |
| instance_cp          |                                                             | map(object{string}) |                   |
| instance_wk          |                                                             | map(object{string}) |                   |
| instance_key_name    | The key name of the Key Pair to use for the instance        | string              |                   |
| elasticip_bn         | ElasticIP of bastion server                                 | string              |                   |
| elasticip_px         | ElasticIP of proxy server                                   | string              |                   |
| private_ip_bn        | ElasticIP of bastion server                                 | string              |                   |
| private_ip_px        | ElasticIP of proxy server                                   | string              |                   |
| instance_type_px     | The instance type of proxy server                           | string              | `e-large`         |
| instance_type_bn     | The instance type of bastion server                         | string              | `e-large`         |
| instance_type_wk     | The instance type of worker                                 | string              | `e-large`         |
| instance_type_cp     | The instance type of control plane                          | string              | `e-large`         |
| accounting_type      | Accounting type                                             | string              | `1`               |
## Outputs

| Name                | Description                              |
| ------------------- | ---------------------------------------- |
| control_plane_lb    | The DNS name of LB for control plane     |
| security_group_name | The security group used in the cluster   |
| private_network_id  | The private network used in the cluster  |
| proxy_info          | The proxy information in cluster         |
| bastion_info        | The bastion information in cluster       |
| worker_info         | The worker information in cluster        |
| control_plane_info  | The control plane information in cluster |


## Requirements

Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:

1. Terraform are [installed](#software-dependencies) on the machine where Terraform is executed.
2. The NIFCLOUD Account you execute the module with has the right permissions.
    - You can set environment variable `NIFCLOUD_ACCESS_KEY_ID` and `NIFCLOUD_SECRET_ACCESS_KEY`
3. Create an SSH key to log in to the server on the NIFCLOUD control panel.
    - The ssh key is used as instance_key_name when creating a cluster

### Software Dependencies

- [Terraform](https://www.terraform.io/downloads.html) 1.3.7
- [Terraform Provider for Nifcloud](https://registry.terraform.io/providers/nifcloud/nifcloud/latest) 1.7.0
