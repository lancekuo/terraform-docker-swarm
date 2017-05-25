variable "swarm-bastion" {
    default = {
        "public_key_path" = "/keys/bastion.pub"
        "private_key_path"= "/keys/bastion"
        "key_name" = "swarm-bastion"
    }
}
variable "swarm-node" {
    default = {
        "public_key_path" = "/keys/swarm.pub"
        "private_key_path"= "/keys/swarm"
        "key_name" = "swarm-node"
    }
}
variable "swarm-manager" {
    default = {
        "public_key_path" = "/keys/manager.pub"
        "private_key_path"= "/keys/manager"
        "key_name" = "swarm-manager"
    }
}
variable "subnet_public" {}
variable "subnet_public_app" {}
variable "subnet_private" {}
variable "subnet_on_public" {}
variable "subnet_per_zone" {}
variable "instance_per_subnet" {}
variable "swarm_manager_count" {}
variable "swarm_node_count" {}
variable "subnets" {}
variable "region" {}
variable "ami" {}
variable "project_name" {}
variable "domain" {}
variable "availability_zones" {}

provider "aws" {
//    region = "ca-central-1"
    region = "${var.region}"
}
