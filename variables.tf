variable "region" {
    default = "ca-central-1"
}
variable "project-name" {
    default = "default"
}
variable "swarm-bastion" {
    default = {
        "public_key_path" = "~/.ssh/id_rsa.pub"
        "private_key_path"= "~/.ssh/id_rsa.bk"
        "key_name" = "-swarm-bastion"
    }
}
provider "aws" {
    region = "${var.region}"
}

terraform {
    backend "s3" {
        bucket = "terraform.internal"
        key    = "terraform.tfstate"
        region = "ca-central-1"
    }
}

