terraform {
    backend "s3" {
        bucket = "terraform.internal"
        key    = "terraform.tfstate"
        region = "ca-central-1"
    }
}

module "vpc" {
    source  = "./base/"
}

module "swarm" {
    source = "./swarm"

    project_name        = "${module.vpc.project_name}"
    region              = "${module.vpc.region}"
    ami                 = "ami-3462de50"
    domain              = "lancekuo.com"
    subnets             = "${module.vpc.subnets}"
    vpc_default_id      = "${module.vpc.vpc_default_id}"
    subnet_public       = "${module.vpc.subnet_public}"
    subnet_public_app   = "${module.vpc.subnet_public_app}"
    subnet_private      = "${module.vpc.subnet_private}"
    subnet_on_public    = "${module.vpc.subnet_on_public}"
    subnet_per_zone     = "${module.vpc.subnet_per_zone}"
    instance_per_subnet = "${module.vpc.instance_per_subnet}"
    swarm_master_count  = "${module.vpc.swarm_master_count}"
    swarm_node_count    = "${((module.vpc.instance_per_subnet*module.vpc.subnet_per_zone)-module.vpc.swarm_master_count)}"
}

output "swarm-node" {
    value = "${module.swarm.swarm_node}"
}
output "swarm-master" {
    value = "${module.swarm.swarm_master}"
}
