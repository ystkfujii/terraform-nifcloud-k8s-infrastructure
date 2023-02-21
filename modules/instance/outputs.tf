output "instance_id" {
  description = "The instance name"
  value       = nifcloud_instance.this.instance_id
}

output "unique_id" {
  description = "The unique ID of instance"
  value       = nifcloud_instance.this.unique_id
}

output "private_ip" {
  description = "The private ip address of instance"
  value       = nifcloud_instance.this.private_ip
}

output "public_ip" {
  description = "The public ip address of instance"
  value       = nifcloud_instance.this.public_ip
}
