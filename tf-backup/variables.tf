variable "region" {}
variable "project" {}

provider "aws" {
    alias  = "${var.region}"
    region = "${var.region}"
}
