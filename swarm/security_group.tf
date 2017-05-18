variable "vpc_default_id" {}

resource "aws_security_group" "swarm-master" {
    name        = "${terraform.env}-swarm-master"
    description = "Gossip and port for swarm master internal"
    vpc_id      = "${var.vpc_default_id}"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }
    ingress {
        from_port       = 2376
        to_port         = 2376
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }
    ingress {
        from_port       = 2375
        to_port         = 2375
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }
    tags {
        Name = "${terraform.env}-swarm-master"
        Env  = "${terraform.env}"
    }
}
resource "aws_security_group" "swarm-node" {
    name        = "${terraform.env}-swarm-node"
    description = "Gossip and port for swarm mode internal"
    vpc_id      = "${var.vpc_default_id}"

    ingress {
        from_port       = 4789
        to_port         = 4789
        protocol        = "tcp"
        self            = true
    }

    ingress {
        from_port       = 4789
        to_port         = 4789
        protocol        = "udp"
        self            = true
    }

    ingress {
        from_port       = 7946
        to_port         = 7946
        protocol        = "tcp"
        self            = true
    }

    ingress {
        from_port       = 7946
        to_port         = 7946
        protocol        = "udp"
        self            = true
    }

    ingress {
        from_port       = 2377
        to_port         = 2377
        protocol        = "tcp"
        self            = true
    }

    ingress {
        from_port       = 2376
        to_port         = 2376
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }

    ingress {
        from_port       = 2375
        to_port         = 2375
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = ["${aws_security_group.swarm-bastion.id}"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    tags {
        Name = "${terraform.env}-swarm-node"
        Env  = "${terraform.env}"
    }
}

resource "aws_security_group" "swarm-bastion" {
    name        = "${terraform.env}-swarm-bastion"
    description = "Access to the bastion machine"
    vpc_id      = "${var.vpc_default_id}"

    ingress {
        from_port   = 22
        to_port     = 22
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
        Name = "${terraform.env}-swarm-bastion"
        Env  = "${terraform.env}"
    }
}
resource "aws_security_group" "grafana-elb" {
    name        = "${terraform.env}-grafana-elb"
    description = "Provide the access to internet to connect to internal grafana site"
    vpc_id      = "${var.vpc_default_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Name = "${terraform.env}-grafana-elb"
        Env  = "${terraform.env}"
    }
}
