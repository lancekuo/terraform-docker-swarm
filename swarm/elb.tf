resource "aws_elb" "grafana" {
    name = "${terraform.env}-grafana"

    subnets         = ["${split(",", var.subnet_public_app)}"]
    security_groups = ["${aws_security_group.grafana-elb.id}"]
    instances       = ["${aws_instance.swarm-node.*.id}", "${aws_instance.swarm-master.*.id}"]

    listener {
        instance_port     = 3000
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    tags  {
        Env = "${terraform.env}"
    }
}
