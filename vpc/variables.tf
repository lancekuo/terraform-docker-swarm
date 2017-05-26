variable "region" {
    default = "ca-central-1"
}
variable "project" {
    default = "default"
}
provider "aws" {
    region = "${var.region}"
}
variable "subnet-on-public" {
    default = 1
}
variable "subnet-per-zone" {
    default = 1
}
variable "instance-per-subnet" {
    default = 2
}
variable "swarm-manager-count" {
    default = 2
}
variable "swarm-node-count" {
    default = 1
}
