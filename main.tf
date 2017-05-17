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
    ami                 = "${lookup(module.vpc.amis, module.vpc.region)}"
    subnets             = "${module.vpc.subnets}"
    vpc_default_id      = "${module.vpc.vpc_default_id}"
    subnet_public       = "${module.vpc.subnet_public}"
    subnet_public_app   = "${module.vpc.subnet_public_app}"
    subnet_private      = "${module.vpc.subnet_private}"
    subnet_on_public    = "${module.vpc.subnet_on_public}"
    subnet_per_zone     = "${module.vpc.subnet_per_zone}"
    instance_per_subnet = "${module.vpc.instance_per_subnet}"
}

output "test" {
    value = "${module.vpc.subnets}"
}
