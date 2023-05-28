variable "availability_zone" {
  description = "The availability zone"
  type        = string
}

variable "prefix" {
  description = "The prefix for the entire cluster"
  type        = string
  default     = "001"
  validation {
    condition     = length(var.prefix) == 3
    error_message = "Must be a 3 charactor long."
  }
}

variable "private_network_subnet" {
  description = "The subnet of private network"
  type        = string
  default     = "192.168.10.0"
  validation {
    condition     = can(cidrnetmask("${var.private_network_subnet}/24"))
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "instances_cp" {
  type = map(object({
    private_ip = string
  }))
}

variable "instances_wk" {
  type = map(object({
    private_ip = string
  }))
}

variable "instance_key_name" {
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "elasticip_bastion" {
  description = "ElasticIP of bastion server"
  type        = string
}

variable "elasticip_proxy" {
  description = "ElasticIP of egress server"
  type        = string
}

variable "instance_count_cp" {
  description = "Number of control plane to be created"
  type        = number
}

variable "instance_count_wk" {
  description = "Number of worker to be created"
  type        = number
}

variable "instance_type_proxy" {
  description = "The instance type of egress server"
  type        = string
  default     = "e-large"
}

variable "instance_type_bastion" {
  description = "The instance type of bastion server"
  type        = string
  default     = "e-large"
}

variable "instance_type_wk" {
  description = "The instance type of worker"
  type        = string
  default     = "e-large"
}

variable "instance_type_cp" {
  description = "The instance type of control plane"
  type        = string
  default     = "e-large"
}

variable "accounting_type" {
  type    = string
  default = "1"
  validation {
    condition = anytrue([
      var.accounting_type == "1", // Monthly
      var.accounting_type == "2", // Pay per use
    ])
    error_message = "Must be a 1 or 2."
  }
}

