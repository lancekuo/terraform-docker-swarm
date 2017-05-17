resource "aws_security_group" "web-elb" {
    name        = "${terraform.env}-web-elb"
    description = "Access to the web"
    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Name              = "${terraform.env}-web-elb"
        Env               = "${terraform.env}"
    }
}
resource "aws_security_group" "web" {
    name        = "${terraform.env}-web"
    description = "Access to the web"
    vpc_id      = "${aws_vpc.default.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = ["${aws_security_group.web-elb.id}"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Name              = "${terraform.env}-web"
        Env               = "${terraform.env}"
    }
}
