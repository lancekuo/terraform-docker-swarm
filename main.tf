module "vpc" {
    source  = "github.com/lancekuo/tf-vpc"

    project = "${var.project}"
    region  = "${var.region}"
}

module "swarm" {
    source                   = "github.com/lancekuo/tf-swarm"

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
    source                   = "github.com/lancekuo/tf-registry"

    project                  = "${var.project}"
    region                   = "${var.region}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    security_group_node_id   = "${module.swarm.security_group_node_id}"
    bastion_public_ip        = "${module.swarm.bastion_public_ip}"
    bastion_private_ip       = "${module.swarm.bastion_private_ip}"
    bastion_private_key_path = "${var.bastion-key["private_key_path"]}"
}

module "backup" {
    source                   = "github.com/lancekuo/tf-backup"

    project                  = "${var.project}"
    region                   = "${var.region}"
}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"

    project                  = "${var.project}"
    region                   = "${var.region}"
    bucket_name              = "${var.s3-bucket_name}"
    filename                 = "${var.s3-filename}"
    s3-region                = "${var.s3-region}"
    node_list                = "${module.swarm.node_list_string}"
}
output "swarm-node" {
    value = "${module.swarm.swarm_node}"
}
output "swarm-master" {
    value = "${module.swarm.swarm_manager}"
}
output "Grafana-DNS" {
    value = "${module.swarm.elb_grafana_dns}"
}
output "Registry-pull-access" {
    value = "${module.registry.access}"
}
output "Registry-pull-secret" {
    value = "${module.registry.secret}"
}
output "Registry-Internal-DNS" {
    value = "${module.registry.registry_internal_dns}"
}
output "Backup-Create-Script-Fileath" {
    value = "${module.backup.lambda_backup_create_script}"
}
output "Backup-Delete-Script-Fileath" {
    value = "${module.backup.lambda_backup_delete_script}"
}
output "Backup-Scheduler" {
    value = "${module.backup.scheduler}"
}
output "SSH-Config" {
    value = "${module.script.ssh_config}"
}
