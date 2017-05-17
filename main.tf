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

    project_name          = "${module.vpc.project_name}"
    region                = "${module.vpc.region}"
    aws_ami               = "${lookup(module.vpc.aws_amis, module.vpc.region)}"
    subnets               = "${module.vpc.subnets}"
    vpc_default_id        = "${module.vpc.vpc_default_id}"
    subnet_public1_id     = "${module.vpc.subnet_public1_id}"
    subnet_public_app1_id = "${module.vpc.subnet_public_app1_id}"
    subnet_public_app2_id = "${module.vpc.subnet_public_app2_id}"
    subnet_private1_id    = "${module.vpc.subnet_private1_id}"
    subnet_private2_id    = "${module.vpc.subnet_private2_id}"
}

output "test" {
    value = "${module.vpc.subnets}"
}
