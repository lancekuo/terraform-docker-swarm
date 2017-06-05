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

module "vpc" {
    source  = "./vpc/"

    project = "${var.project}"
    region  = "${var.region}"
}

module "swarm" {
    source              = "./swarm"

    project             = "${var.project}"
    region              = "${var.region}"

    ami                 = "${var.docker-ami}"
    domain              = "lancekuo.com"
    vpc_default_id      = "${module.vpc.vpc_default_id}"

    subnet_public       = "${module.vpc.subnet_public}"
    subnet_public_app   = "${module.vpc.subnet_public_app}"
    subnet_private      = "${module.vpc.subnet_private}"

    availability_zones  = "${module.vpc.availability_zones}"
    subnet_per_zone     = "${module.vpc.subnet_per_zone}"
    instance_per_subnet = "${module.vpc.instance_per_subnet}"
    subnet_on_public    = "${module.vpc.subnet_on_public}"
    swarm_manager_count = "${module.vpc.swarm_manager_count}"
    swarm_node_count    = "${(module.vpc.instance_per_subnet*length(split(",", module.vpc.availability_zones))-module.vpc.swarm_manager_count)}"
}

module "registry" {
    source                         = "./registry"

    project                        = "${var.project}"
    region                         = "${var.region}"

    vpc_default_id                 = "${module.vpc.vpc_default_id}"
    bastion_public_ip              = "${element(split(",", module.swarm.bastion_public_ip), 0)}"
    bastion_private_ip             = "${element(split(",", module.swarm.bastion_private_ip), 0)}"
    swarm_bastion_private_key_path = "${module.swarm.swarm_bastion_private_key_path}"
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
