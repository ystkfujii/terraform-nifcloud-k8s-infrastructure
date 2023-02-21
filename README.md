# terraform-nifcloud-k8s-infrastructure

This Terraform module will provision the nifcloud infrastructure for a kubernetes cluster.
To build a kubernetes cluster, you will need to use a another tool such as [kubespray.io](https://kubespray.io/).

## Usage

There are examples included in the examples folder but simple usage is as follows:

```hcl
locals {
  instance_key_name     = "deployerkey"
}

provider "nifcloud" {
  region     = "jp-west-1"
}

# elastic ip
resource "nifcloud_elastic_ip" "bastion" {
  ip_type           = false
  availability_zone = "west-11"
  description       = "bastion"
}
resource "nifcloud_elastic_ip" "egress" {
  ip_type           = false
  availability_zone = "west-11"
  description       = "egress"
}

# k8s cluster
module "k8s_cluster" {
  source = "../"

  availability_zone = "west-11"

  instance_key_name = local.instance_key_name

  elasticip_bastion = nifcloud_elastic_ip.bastion.public_ip
  elasticip_egress = nifcloud_elastic_ip.egress.public_ip

  instance_count_cp = 1
  instance_count_wk = 2
}
```

Then perform the following commands on the root folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

## Inputs

| Name                  | Description                                          | Type   | Default   |
| --------------------- | ---------------------------------------------------- | ------ | --------- |
| availability_zone     | The availability zone                                | string |           |
| prefix                | The prefix for the entire cluster                    | string | `001`     |
| instance_key_name     | The key name of the Key Pair to use for the instance | string |           |
| elasticip_bastion     | ElasticIP of bastion server                          | string |           |
| elasticip_egress      | ElasticIP of egress server                           | string |           |
| instance_count_cp     | Number of controle plane to be created               | number |           |
| instance_count_wk     | Number of worker to be created                       | number |           |
| instance_type_egress  | The instance type of egress server                   | string | `e-large` |
| instance_type_bastion | The instance type of bastion server                  | string | `e-large` |
| instance_type_wk      | The instance type of worker                          | string | `e-large` |
| instance_type_cp      | The instance type of controle plane                  | string | `e-large` |
| accounting_type       | Accounting type                                      | string | `1`       |

## Outputs

| Name                  | Description                                          |
| --------------------- | ---------------------------------------------------- |
| controle_plnae_lb     | The DNS name of LB for controle plane                |
| security_group_name   | The security group used in the cluster               |
| worker_instance_info  | The Worker infomation in cluste                      |


## Requirements

Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:

1. Terraform are [installed](#software-dependencies) on the machine where Terraform is executed.
2. The Nifcloud Account you execute the module with has the right permissions.
    - You can set environment variable `NIFCLOUD_ACCESS_KEY_ID` and `NIFCLOUD_SECRET_ACCESS_KEY`
3. Create an SSH key to log in to the server from the Nifcloud control panel.
    - The ssh key is used as instance_key_name when creating a cluster

### Software Dependencies

- [Terraform](https://www.terraform.io/downloads.html) 1.3.7
- [Terraform Provider for Nifcloud](https://registry.terraform.io/providers/nifcloud/nifcloud/latest) 1.7.0