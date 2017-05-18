resource "aws_instance" "swarm-node" {
    count                  = "${var.instance_per_subnet*var.subnet_per_zone}"
    instance_type          = "t2.small"
    ami                    = "${var.ami}"
    key_name               = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-bastion.id}"]
    subnet_id              = "${element(split(",", var.subnet_public_app), count.index)}"

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file(var.swarm-bastion["private_key_path"])}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get -y update",
            "sudo apt-get -y install unzip libltdl7",
            "curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/edge/amd64/docker-ce_17.05.0~ce-0~ubuntu-xenial_amd64.deb -o package.deb;sudo dpkg -i package.deb",
        ]
    }
    tags  {
        Name = "${terraform.env}-swarm-node-${count.index}"
        Env  = "${terraform.env}"
    }
}
