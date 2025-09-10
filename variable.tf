# network
variable "region" {}
variable "availability_zone" {}
variable "subnet_id" {}
variable "ssh_port" {}
variable "security_group_id" {}

# instance
variable "instance_type" {}
variable "max_price" {}
variable "ami_id" {}
variable "root_volume_size" {}
# variable "tags" {
#   type        = list(string)
# }

# domain
variable "domain" {}
variable "hosted_zone_id" {}

# profiles
variable "user_name" {}
variable "keypair_name" {}
variable "profile_name" {}

# storage
variable "device_name" {}
variable "volume_id" {}
