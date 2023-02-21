variable "availability_zone" {
  description = "The availability zone"
  type        = string
}
variable "prefix" {
  description = "The prefix for the entire private network"
  type        = string
  default     = "001"
}

variable "private_network_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.private_network_cidr))
    error_message = "Must be a valid IPv4 CIDR block address"
  }
}

variable "router_ip_address" {
  type = string
}

variable "dhcp_config" {
  type = object({
    ipaddress_pool_start = string
    ipaddress_pool_stop  = string
  })
}

variable "router_type" {
  type    = string
  default = "small"
}

variable "accounting_type" {
  type    = string
  default = "1"
  validation {
    condition = anytrue([
      var.accounting_type == "1", // Monthly
      var.accounting_type == "2", // Pay per use
    ])
    error_message = "Must be a 1 or 2"
  }
}