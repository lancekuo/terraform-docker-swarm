
variable "swarm-bastion" {
    default = {
        "public_key_path" = "~/.ssh/id_rsa.pub"
        "private_key_path"= "~/.ssh/id_rsa.bk"
        "key_name" = "-swarm-bastion"
    }
}
variable "subnet_public1_id" {}
variable "subnet_public_app1_id" {}
variable "subnet_public_app2_id" {}
variable "subnet_private1_id" {}
variable "subnet_private2_id" {}
variable "subnets" {}
variable "region" {}
variable "aws_ami" {}
variable "project_name" {}

provider "aws" {
    region = "${var.region}"
}
