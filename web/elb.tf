resource "aws_elb" "web" {
    name = "${terraform.env}-web"

    subnets         = ["${aws_subnet.public1.id}"]
    security_groups = ["${aws_security_group.web-elb.id}"]
    instances       = ["${aws_instance.swarm-bastion.id}"]

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    tags  {
        Env = "${terraform.env}"
    }
}
