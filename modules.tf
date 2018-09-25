provider "aws" {
    region = "${var.aws_region}"
}
module "vpc" {
    source                         = "github.com/lancekuo/tf-vpc"

    project                        = "${var.project}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_public_subnet_per_az     = "${var.count_public_subnet_per_az}"
    count_private_subnet_per_az    = "${var.count_private_subnet_per_az}"
}

module "registry" {
    source                   = "github.com/lancekuo/tf-registry"

    project                  = "${var.project}"
    aws_region               = "${var.aws_region}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    security_group_node_id   = "${aws_security_group.node.id}"
    bastion_public_ip        = "${aws_eip.bastion.public_ip}"
    bastion_private_ip       = "${aws_eip.bastion.private_ip}"
    rsa_key_bastion          = "${var.rsa_key_bastion}"

    create_registry_bucket   = "${var.create_registry_bucket}"
    enableRegistryPush       = "${var.enableRegistryPush}"
    s3_bucketname_registry   = "${var.s3_bucketname_registry}"

    route53_internal_zone_id = "${module.vpc.route53_internal_zone_id}"
}

module "backup" {
    source                   = "github.com/lancekuo/tf-backup"

    project                  = "${var.project}"
}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"

    project                  = "${var.project}"
    region                   = "${var.aws_region}"
    bucket_name              = "${var.terraform_backend_s3_bucketname}"
    filename                 = "${var.terraform_backend_s3_filename}"
    s3-region                = "${var.terraform_backend_s3_region}"
    node_list                = "${join(",",aws_instance.node.*.id)}"

    enable_s3_backend        = false
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