output "subnets" {
    value = "${var.subnets}"
}

output "region" {
    value = "${var.region}"
}

output "aws_amis" {
    value = "${var.aws_amis}"
}

output "project_name" {
    value = "${var.project-name}"
}

output "vpc_default_id" {
    value = "${aws_vpc.default.id}" 
}

output "subnet_public1_id" {
    value = "${aws_subnet.public1.id}"
}
output "subnet_public_app1_id" {
    value = "${aws_subnet.public-app1.id}"
}
output "subnet_public_app2_id" {
    value = "${aws_subnet.public-app2.id}"
}
output "subnet_private1_id" {
    value = "${aws_subnet.private1.id}"
}
output "subnet_private2_id" {
    value = "${aws_subnet.private2.id}"
}
