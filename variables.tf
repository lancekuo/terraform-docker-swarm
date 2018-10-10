#terraform {
#    backend "s3" {
#        bucket = "tf.docker.internal"
#        key    = "terraform.tfstate"
#        region = "us-east-2"
#    }
#}
# common
variable "aws_ami_docker"                  {}
variable "aws_region"                      {}
variable "domain"                          {}
variable "project"                         {}

# module VPC
variable "count_bastion_subnet_on_public"  {}
variable "count_private_subnet_per_az"     {}
variable "count_public_subnet_per_az"      {}

# module registry
variable "enableRegistryBucket"            {}
variable "enableRegistryPush"              {}
variable "registry_bucketname"             {}

# module backup
variable "event_schedule"                  {}

# module script
variable "terraform_backend_s3_bucketname" {}
variable "terraform_backend_s3_filename"   {}
variable "terraform_backend_s3_region"     {}

# === Variables ===================================
locals {
    subnet_private_ids        = "${module.vpc.subnet_private_ids}"
    subnet_public_app_ids     = "${module.vpc.subnet_public_app_ids}"
    subnet_public_bastion_ids = "${module.vpc.subnet_public_bastion_ids}"
    vpc_default_id            = "${module.vpc.vpc_default_id}"
    count_swarm_node          = "${(var.count_instance_per_az*length(module.vpc.availability_zones)-var.count_swarm_manager)}"
}
variable "count_instance_per_az"           {}
variable "count_subnet_per_az"             {}
variable "count_swarm_manager"             {}
variable "instance_type_bastion"           {}
variable "instance_type_manager"           {}
variable "instance_type_node"              {}

variable "rsa_key_bastion"                 {
    type="map"
    default={
        "public_key_path"  = "/keys/bastion.pub"
        "private_key_path" = "/keys/bastion"
        "aws_key_name"     = "bastion"
    }
}
variable "rsa_key_node"                 {
    type="map"
    default={
        "public_key_path"  = "/keys/node.pub"
        "private_key_path" = "/keys/node"
        "aws_key_name"     = "node"
    }
}
variable "rsa_key_manager"                 {
    type="map"
    default={
        "public_key_path"  = "/keys/manager.pub"
        "private_key_path" = "/keys/manager"
        "aws_key_name"     = "manager"
    }
}
