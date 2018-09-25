#terraform {
#    backend "s3" {
#        bucket = "tf.docker.internal"
#        key    = "terraform.tfstate"
#        region = "us-east-2"
#    }
#}
variable "terraform_backend_s3_bucketname" {}
variable "terraform_backend_s3_filename"   {}
variable "terraform_backend_s3_region"     {}
variable "aws_region"                      {}
variable "aws_ami_docker"                  {}
variable "project"                         {}
variable "domain"                          {}

variable "instance_type_bastion"           {}
variable "instance_type_manager"           {}
variable "instance_type_node"              {}

variable "rsa_key_bastion"                 {type="map"}
variable "rsa_key_node"                    {type="map"}
variable "rsa_key_manager"                 {type="map"}

variable "count_bastion_subnet_on_public"  {}
variable "count_public_subnet_per_az"      {}
variable "count_private_subnet_per_az"     {}
variable "count_subnet_per_az"             {}
variable "count_instance_per_az"           {}
variable "count_swarm_manager"             {}

variable "create_registry_bucket"          {}
variable "enableRegistryPush"              {}
variable "s3_bucketname_registry"          {}

locals {
    count_swarm_node          = "${(var.count_instance_per_az*length(module.vpc.availability_zones)-var.count_swarm_manager)}"
    subnet_public_bastion_ids = "${module.vpc.subnet_public_bastion_ids}"
    subnet_public_app_ids     = "${module.vpc.subnet_public_app_ids}"
    subnet_private_ids        = "${module.vpc.subnet_private_ids}"
    vpc_default_id            = "${module.vpc.vpc_default_id}"
}
