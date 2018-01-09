provider "aws" {
    alias   = "${var.aws_profile}"
    region  = "${var.aws_region}"
    profile = "${var.aws_profile}"
}

module "vpc" {
    providers = {
        "aws" = "aws.${var.aws_profile}"
    }

    source                         = "github.com/lancekuo/tf-vpc"

    project                        = "${var.project}"
    aws_region                     = "${var.aws_region}"
    aws_profile                    = "${var.aws_profile}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_public_subnet_per_az     = "${var.count_public_subnet_per_az}"
    count_private_subnet_per_az    = "${var.count_private_subnet_per_az}"
}

module "swarm" {
    providers = {
        "aws" = "aws.${var.aws_profile}"
    }
    source                         = "github.com/lancekuo/tf-swarm"

    project                        = "${var.project}"
    aws_region                     = "${var.aws_region}"
    aws_profile                    = "${var.aws_profile}"

    aws_ami_docker                 = "${var.aws_ami_docker}"
    domain                         = "lancekuo.com"
    vpc_default_id                 = "${module.vpc.vpc_default_id}"

    instance_type_bastion          = "${var.instance_type_bastion}"
    instance_type_manager          = "${var.instance_type_manager}"
    instance_type_node             = "${var.instance_type_node}"

    rsa_key_bastion                = "${var.rsa_key_bastion}"
    rsa_key_manager                = "${var.rsa_key_manager}"
    rsa_key_node                   = "${var.rsa_key_node}"

    subnet_public_bastion_ids      = "${module.vpc.subnet_public_bastion_ids}"
    subnet_public_app_ids          = "${module.vpc.subnet_public_app_ids}"
    subnet_private_ids             = "${module.vpc.subnet_private_ids}"
    availability_zones             = "${module.vpc.availability_zones}"
    route53_internal_zone_id       = "${module.vpc.route53_internal_zone_id}"

    count_bastion_subnet_on_public = "${var.count_bastion_subnet_on_public}"
    count_instance_per_az          = "${var.count_instance_per_az}"
    count_swarm_manager            = "${var.count_swarm_manager}"
    count_swarm_node               = "${(var.count_instance_per_az*var.count_swarm_node)}"

    mount_point                    = "/opt/prometheus"
    device_file                    = "/dev/xvdg"
    partition_file                 = "/dev/xvdg1"
}

module "registry" {
    providers = {
        "aws" = "aws.${var.aws_profile}"
    }
    source                   = "github.com/lancekuo/tf-registry"

    project                  = "${var.project}"
    aws_region               = "${var.aws_region}"
    aws_profile              = "${var.aws_profile}"

    vpc_default_id           = "${module.vpc.vpc_default_id}"
    security_group_node_id   = "${module.swarm.security_group_node_id}"
    bastion_public_ip        = "${module.swarm.bastion_public_ip}"
    bastion_private_ip       = "${module.swarm.bastion_private_ip}"
    rsa_key_bastion          = "${var.rsa_key_bastion}"

    route53_internal_zone_id = "${module.vpc.route53_internal_zone_id}"
    s3_bucketname_registry   = "${var.s3_bucketname_registry}"
    create_registry_bucket   = false
    enableRegistryPush       = false
}

module "backup" {
    providers = {
        "aws" = "aws.${var.aws_profile}"
    }
    source                   = "github.com/lancekuo/tf-backup"

    project                  = "${var.project}"
    region                   = "${var.aws_region}"
    aws_profile              = "${var.aws_profile}"
}

module "script" {
    source                   = "github.com/lancekuo/tf-tools"

    project                  = "${var.project}"
    region                   = "${var.aws_region}"
    bucket_name              = "${var.terraform_backend_s3_bucketname}"
    filename                 = "${var.terraform_backend_s3_filename}"
    s3-region                = "${var.terraform_backend_s3_region}"
    node_list                = "${module.swarm.node_list_string}"

    enable_s3_backend        = false
}
output "Kibana-DNS" {
    value = "${module.swarm.elb_kibana_dns}"
}
output "Grafana-DNS" {
    value = "${module.swarm.elb_grafana_dns}"
}
output "swarm-node" {
    value = "${module.swarm.swarm_node}"
}
output "swarm-master" {
    value = "${module.swarm.swarm_manager}"
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
output "Logstash-Internal-DNS" {
    value = "${module.swarm.logstash_internal_dns}"
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
