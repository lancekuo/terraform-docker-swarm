variable "swarm-bastion" {
    default = {
        "public_key_path" = "~/.ssh/id_rsa.pub"
        "private_key_path"= "~/.ssh/id_rsa.bk"
        "key_name" = "-swarm-bastion"
    }
}
variable "subnet_public" {}
variable "subnet_public_app" {}
variable "subnet_private" {}
variable "subnet_on_public" {}
variable "subnet_per_zone" {}
variable "instance_per_subnet" {}
variable "swarm_master_count" {}
variable "swarm_node_count" {}
variable "subnets" {}
variable "region" {}
variable "ami" {}
variable "project_name" {}
variable "domain" {}

provider "aws" {
    region = "${var.region}"
}
