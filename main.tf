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

variable "project" {
    default = "WRS"
}

module "vpc" {
    source  = "./base/"

    project             = "${var.project}"
    region              = "${var.region}"
}

module "swarm" {
    source = "./swarm"

    project             = "${var.project}"
    region              = "${var.region}"
    ami                 = "ami-06436563"
    domain              = "lancekuo.com"
    subnets             = "${module.vpc.subnets}"
    availability_zones  = "${module.vpc.availability_zones}"
    vpc_default_id      = "${module.vpc.vpc_default_id}"
    subnet_public       = "${module.vpc.subnet_public}"
    subnet_public_app   = "${module.vpc.subnet_public_app}"
    subnet_private      = "${module.vpc.subnet_private}"
    subnet_on_public    = "${module.vpc.subnet_on_public}"
    subnet_per_zone     = "${module.vpc.subnet_per_zone}"
    instance_per_subnet = "${module.vpc.instance_per_subnet}"
    swarm_manager_count = "${module.vpc.swarm_manager_count}"
    swarm_node_count    = "${((module.vpc.instance_per_subnet*module.vpc.subnet_per_zone)-module.vpc.swarm_manager_count)}"
}

output "swarm-node" {
    value = "${module.swarm.swarm_node}"
}
output "swarm-master" {
    value = "${module.swarm.swarm_manager}"
}
