resource "aws_key_pair" "swarm-bastion" {
    key_name   = "${terraform.env}-${var.region}-${var.swarm-bastion["key_name"]}"
    public_key = "${file("${path.module}/script/${var.swarm-bastion["public_key_path"]}")}"
}
resource "aws_instance" "swarm-bastion" {
    instance_type          = "t2.nano"
    ami                    = "${var.ami}"
    key_name               = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-bastion.id}"]
    subnet_id              = "${element(split(",", var.subnet_public), var.subnet_on_public)}"

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("${path.module}/script/${var.swarm-bastion["private_key_path"]}")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo curl -L https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && chmod +x /tmp/docker-machine && sudo cp /tmp/docker-machine /usr/local/bin/docker-machine",
            "sudo curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose",
            "sudo systemctl stop docker",
            "sudo systemctl disable docker",
        ]
    }
    tags  {
        Name           = "${terraform.env}-swarm-bastion"
        Env            = "${terraform.env}"
        Docker-machine = "sudo curl -L https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && chmod +x /tmp/docker-machine && sudo cp /tmp/docker-machine /usr/local/bin/docker-machine"
        Docker-compose = "sudo curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    }
}
resource "aws_eip" "swarm-bastion" {
    vpc = true
    instance = "${aws_instance.swarm-bastion.id}"
}
