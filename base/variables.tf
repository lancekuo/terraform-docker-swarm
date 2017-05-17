variable "region" {
    default = "ca-central-1"
}
variable "project-name" {
    default = "default"
}
provider "aws" {
    region = "${var.region}"
}
