resource "aws_elb" "grafana" {
    name = "${terraform.env}-grafana"

    subnets         = ["${var.subnet_public_app1_id}", "${var.subnet_public_app2_id}"]
    security_groups = ["${aws_security_group.grafana-elb.id}"]

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
