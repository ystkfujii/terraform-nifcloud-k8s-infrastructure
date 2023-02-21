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

variable "instance_key_name" {
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "elasticip_bastion" {
  description = "ElasticIP of bastion server"
  type        = string
}

variable "elasticip_egress" {
  description = "ElasticIP of egress server"
  type        = string
}

variable "instance_count_cp" {
  description = "Number of controle plane to be created"
  type        = number
}

variable "instance_count_wk" {
  description = "Number of worker to be created"
  type        = number
}

variable "instance_type_egress" {
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
  description = "The instance type of controle plane"
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

