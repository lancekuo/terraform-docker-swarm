terraform {
    backend "s3" {
        bucket = "terraform.internal"
        key    = "terraform.tfstate"
        region = "ca-central-1"
    }
}

variable "s3-bucket_name" {
    default = "terraform.internal"
}
variable "s3-filename" {
    default = "terraform.tfstate"
}
variable "s3-region" {
    default = "ca-central-1"
}
variable "region" {
    default = "us-east-2"
}

variable "docker-ami" {
    default = "ami-afa98fca"
}

variable "project" {
    default = "WRS"
}

variable "bastion-key" {
    default = {
        "public_key_path"  = "/keys/bastion.pub"
        "private_key_path" = "/keys/bastion"
        "aws_key_name"     = "bastion"
    }
}
variable "node-key" {
    default = {
        "public_key_path"  = "/keys/node.pub"
        "private_key_path" = "/keys/node"
        "aws_key_name"     = "node"
    }
}
variable "manager-key" {
    default = {
        "public_key_path"  = "/keys/manager.pub"
        "private_key_path" = "/keys/manager"
        "aws_key_name"     = "manager"
    }
}

