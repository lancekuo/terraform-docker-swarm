resource "aws_route53_record" "manager" {
    zone_id  = "${module.vpc.route53_internal_zone_id}"
    name     = "managers.docker"
    type     = "A"
    ttl      = "300"
    records  = ["${aws_instance.manager.*.private_ip}"]
}

resource "aws_route53_record" "worker" {
    zone_id  = "${module.vpc.route53_internal_zone_id}"
    name     = "workers.docker"
    type     = "A"
    ttl      = "300"
    records  = ["${aws_instance.node.*.private_ip}"]
}
