terraform {
    backend "s3" {
        bucket = "terraform.internal"
        key    = "terraform.tfstate"
        region = "ca-central-1"
    }
}
variable "region" {
    default = "us-east-2"
}

variable "docker-ami" {
    default = "ami-d63610b3"
}

variable "project" {
    default = "WRS"
}

variable "bastion-key" {
    default = {
        "public_key_path"  = "/keys/bastion.pub"
        "private_key_path" = "/keys/bastion"
        "aws_key_name"     = "bastion"
    }
}
variable "node-key" {
    default = {
        "public_key_path"  = "/keys/swarm.pub"
        "private_key_path" = "/keys/swarm"
        "aws_key_name"     = "node"
    }
}
variable "manager-key" {
    default = {
        "public_key_path"  = "/keys/manager.pub"
        "private_key_path" = "/keys/manager"
        "aws_key_name"     = "manager"
    }
}

module "vpc" {
    source  = "./vpc/"

    project = "${var.project}"
    region  = "${var.region}"
}

module "swarm" {
    source                   = "./swarm"

    project                  = "${var.project}"
    region                   = "${var.region}"

    ami                      = "${var.docker-ami}"
    domain                   = "lancekuo.com"
    vpc_default_id           = "${module.vpc.vpc_default_id}"

    bastion_public_key_path  = "${var.bastion-key["public_key_path"]}"
    bastion_private_key_path = "${var.bastion-key["private_key_path"]}"
    bastion_aws_key_name     = "${var.bastion-key["aws_key_name"]}"
    manager_public_key_path  = "${var.manager-key["public_key_path"]}"
    manager_private_key_path = "${var.manager-key["private_key_path"]}"
    manager_aws_key_name     = "${var.manager-key["aws_key_name"]}"
    node_public_key_path     = "${var.node-key["public_key_path"]}"
    node_private_key_path    = "${var.node-key["private_key_path"]}"
    node_aws_key_name        = "${var.node-key["aws_key_name"]}"

    subnet_public            = "${module.vpc.subnet_public}"
    subnet_public_app        = "${module.vpc.subnet_public_app}"
    subnet_private           = "${module.vpc.subnet_private}"

    availability_zones       = "${module.vpc.availability_zones}"
    subnet_per_zone          = "${module.vpc.subnet_per_zone}"
    instance_per_subnet      = "${module.vpc.instance_per_subnet}"
    subnet_on_public         = "${module.vpc.subnet_on_public}"
    swarm_manager_count      = "${module.vpc.swarm_manager_count}"
    swarm_node_count         = "${(module.vpc.instance_per_subnet*length(split(",", module.vpc.availability_zones))-module.vpc.swarm_manager_count)}"
}

module "registry" {
    source                   = "./registry"

    project                  = "${var.project}"
    region                   = "${var.region}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    bastion_public_ip        = "${module.swarm.bastion_public_ip}"
    bastion_private_ip       = "${module.swarm.bastion_private_ip}"
    bastion_private_key_path = "${var.bastion-key["private_key_path"]}"
}

output "swarm-node" {
    value = "${module.swarm.swarm_node}"
}
output "swarm-master" {
    value = "${module.swarm.swarm_manager}"
}
output "access-key" {
    value = "${module.registry.access}"
}
output "secret" {
    value = "${module.registry.secret}"
}
