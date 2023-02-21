variable "availability_zone" {
  description = "The availability zone"
  type        = string
}

variable "instance_id" {
  description = "The instance name"
  type        = string
}

variable "key_name" {
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "security_group_name" {
  description = "The security group name to associate with instance"
  type        = string
}

variable "public_ip_address" {
  description = "The public ip address of instance"
  type        = string
  default     = null
}

variable "interface_private" {
  description = "The IP address and network ID for the private interface"
  type = object({
    ip_address = string
    network_id = string
  })
  default = null
  validation {
    condition     = var.interface_private == null ? true : can(cidrnetmask(var.interface_private.ip_address))
    error_message = "Must be a valid IPv4 CIDR block address"
  }
}

variable "instance_type" {
  description = "The type of instance to start. Updates to this field will trigger a stop/start of the instance"
  type        = string
  default     = "e-large"
}

variable "ubuntu_image_name" {
  description = "The name of image"
  type        = string
  default     = "Ubuntu Server 22.04 LTS"
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
    error_message = "Must be a 1 or 2"
  }
}