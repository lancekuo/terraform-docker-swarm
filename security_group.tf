resource "aws_security_group" "manager" {
    name        = "${terraform.workspace}-manager"
    description = "Gossip and port for swarm manager internal"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
    }
    ingress {
        from_port       = 2376
        to_port         = 2376
        protocol        = "tcp"
        description     = "Docker API SSL"
        security_groups = ["${aws_security_group.bastion.id}"]
    }
    ingress {
        from_port       = 2375
        to_port         = 2375
        protocol        = "tcp"
        description     = "Docker API"
        security_groups = ["${aws_security_group.bastion.id}"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}
resource "aws_security_group" "node" {
    name        = "${terraform.workspace}-node"
    description = "Gossip and port for swarm mode internal"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port       = 9323
        to_port         = 9323
        protocol        = "tcp"
        description     = "Docker Metrics"
        self            = true
    }

    ingress {
        from_port       = 4789
        to_port         = 4789
        protocol        = "tcp"
        description     = "Swarm internal networking/gossip"
        self            = true
    }

    ingress {
        from_port       = 4789
        to_port         = 4789
        protocol        = "udp"
        description     = "Swarm internal networking/gossip"
        self            = true
    }

    ingress {
        from_port       = 7946
        to_port         = 7946
        protocol        = "tcp"
        description     = "Swarm internal networking/gossip"
        self            = true
    }

    ingress {
        from_port       = 7946
        to_port         = 7946
        protocol        = "udp"
        description     = "Swarm internal networking/gossip"
        self            = true
    }

    ingress {
        from_port       = 2377
        to_port         = 2377
        protocol        = "tcp"
        description     = "Swarm API"
        self            = true
    }

    ingress {
        from_port       = 2376
        to_port         = 2376
        protocol        = "tcp"
        description     = "Docker API SSL"
        security_groups = ["${aws_security_group.bastion.id}"]
    }

    ingress {
        from_port       = 2375
        to_port         = 2375
        protocol        = "tcp"
        description     = "Docker API"
        self            = true
        security_groups = ["${aws_security_group.bastion.id}"]
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}

resource "aws_security_group" "bastion" {
    name        = "${terraform.workspace}-bastion"
    description = "Access to the bastion machine"
    vpc_id      = "${local.vpc_default_id}"

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
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}

resource "aws_security_group" "swarm-outgoing-service" {
    name        = "${terraform.workspace}-swarm-outgoing-service"
    description = "Provide the access to internet to connect to internal sites"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        description = "Grafana"
        security_groups = ["${aws_security_group.grafana-elb.id}"]
    }
    ingress {
        from_port   = 5601
        to_port     = 5601
        protocol    = "tcp"
        description = "Kibana"
        security_groups = ["${aws_security_group.kibana-elb.id}"]
    }
    ingress {
        from_port   = 9090
        to_port     = 9090
        protocol    = "tcp"
        description = "Prometheus"
        security_groups = ["${aws_security_group.node.id}"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}
resource "aws_security_group" "private_registry" {
    name        = "${terraform.workspace}-registry"
    description = "Access to Private Registry service"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "Registry"
        security_groups = ["${aws_security_group.node.id}", "${aws_security_group.manager.id}"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}

resource "aws_security_group" "logstash" {
    name        = "${terraform.workspace}-logstash"
    description = "Provide the access to logstash internally."
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port   = 5000
        to_port     = 5000
        protocol    = "udp"
        description = "Logstash"
        security_groups = ["${aws_security_group.node.id}"]
    }
    ingress {
        from_port   = 9600
        to_port     = 9600
        protocol    = "tcp"
        description = "Logstash API"
        security_groups = ["${aws_security_group.node.id}"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}
resource "aws_security_group" "grafana-elb" {
    name        = "${terraform.workspace}-grafana-elb"
    description = "Provide the access to internet to connect to internal grafana site"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}
resource "aws_security_group" "kibana-elb" {
    name        = "${terraform.workspace}-kibana-elb"
    description = "Provide the access to internet to connect to internal kibana site"
    vpc_id      = "${local.vpc_default_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    tags {
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
    }
}
