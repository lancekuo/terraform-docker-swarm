variable "region" {
    default = "ca-central-1"
}
variable "project-name" {
    default = "default"
}
provider "aws" {
    region = "${var.region}"
}
variable "subnet-on-public" {
    default = 1
}
variable "subnet-per-zone" {
    default = 2
}
variable "instance-per-subnet" {
    default = 2
}
