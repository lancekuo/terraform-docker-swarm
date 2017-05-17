resource "aws_elb" "grafana" {
    name = "${terraform.env}-grafana"

    subnets         = ["${aws_subnet.public-app1.id}", "${aws_subnet.public-app2.id}"]
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
