provider "aws" {
    region = "${var.aws_region}"
}
module "vpc" {
    source                         = "github.com/lancekuo/tf-vpc"
    project                        = "${var.project}"
    aws_region                     = "${var.aws_region}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_public_subnet_per_az     = "${var.count_public_subnet_per_az}"
    count_private_subnet_per_az    = "${var.count_private_subnet_per_az}"
}

module "registry" {
    source                   = "github.com/lancekuo/tf-registry"
    project                  = "${var.project}"
    aws_region               = "${var.aws_region}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    route53_internal_zone_id = "${module.vpc.route53_internal_zone_id}"

    security_group_node_id   = "${aws_security_group.node.id}"
    bastion_public_ip        = "${aws_eip.bastion.public_ip}"
    bastion_private_ip       = "${aws_eip.bastion.private_ip}"
    bastion_rsa_key          = "${var.rsa_key_bastion}"
    enableRegistryBucket     = "${var.enableRegistryBucket}"
    enableRegistryPush       = "${var.enableRegistryPush}"
    registry_bucketname      = "${var.registry_bucketname}"
}

module "backup" {
    source                   = "github.com/lancekuo/tf-backup"
    project                  = "${var.project}"
    aws_region               = "${var.aws_region}"

    event_schedule           = "${var.event_schedule}"
}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"
    project                  = "${var.project}"

    s3_bucket_name           = "${var.terraform_backend_s3_bucketname}"
    s3_tf_filename           = "${var.terraform_backend_s3_filename}"
    s3_region                = "${var.terraform_backend_s3_region}"
    enableS3Backend          = false

    node_list                = "${join(",",aws_instance.node.*.id)}"
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
output "swarm_manager" {
    value = "${aws_instance.manager.*.private_dns}"
}
output "swarm_node" {
    value = "${aws_instance.node.*.private_dns}"
}
output "bastion_public_ip" {
    value = "${aws_eip.bastion.public_ip}"
}
output "bastion_private_ip" {
    value = "${aws_eip.bastion.private_ip}"
}
output "node_list_string" {
    value = "${join(",",aws_instance.node.*.id)}"
}

output "security_group_node_id" {
    value = "${aws_security_group.node.id}"
}

output "elb_grafana_dns" {
    value = "${aws_elb.grafana.dns_name}"
}
output "elb_kibana_dns" {
    value = "${aws_elb.kibana.dns_name}"
}
output "manager_internal_dns" {
    value = "${aws_route53_record.manager.fqdn}"
}
output "worker_internal_dns" {
    value = "${aws_route53_record.worker.fqdn}"
}
