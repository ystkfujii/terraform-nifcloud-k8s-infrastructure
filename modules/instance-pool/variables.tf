variable "availability_zone" {
  description = "The availability zone"
  type        = string
}

variable "az_short_name" {
  description = "The short name for availability zone"
  type        = string
  validation {
    condition     = length(var.az_short_name) == 3
    error_message = "Must be a 3 charactor long."
  }
}

variable "prefix" {
  description = "The prefix for the entire instance pool"
  type        = string
  default     = "001"
  validation {
    condition     = length(var.prefix) == 3
    error_message = "Must be a 3 charactor long."
  }
}

variable "role" {
  description = "The role of instance-pool"
  type        = string
  validation {
    condition     = length(var.role) == 2
    error_message = "Must be a 2 charactor long."
  }
}

variable "instance_key_name" {
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to be created"
  type        = number
  validation {
    condition     = var.instance_count > 0
    error_message = "Must be greater than to 0."
  }
}

variable "private_network_id" {
  description = "The network ID for the private interface"
  type        = string
}

variable "private_network_subnet" {
  type = number
  validation {
    condition     = var.private_network_subnet > 0 && var.private_network_subnet < 32
    error_message = "Must be greater than to 0 and less than 32."
  }

}

variable "private_network_3octet" {
  description = "To the third octet of the private network"
  type        = string
}

variable "lb_portforward" {
  description = "Specify the listening port of the load balancer and the destination port of the server"
  type = object({
    from = number
    to   = number
  })
  default = null
}

variable "instance_type" {
  description = "The type of instance to start. Updates to this field will trigger a stop/start of the instance"
  type        = string
  default     = "e-large"
}

variable "accounting_type" {
  description = "Accounting type"
  type        = string
  default     = "1"
  validation {
    condition = anytrue([
      var.accounting_type == "1", // Monthly
      var.accounting_type == "2", // Pay per use
    ])
    error_message = "Must be a 1 or 2."
  }
}

