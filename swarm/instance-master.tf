resource "aws_instance" "swarm-master" {
    count                       = "${var.swarm_master_count}"
    instance_type               = "t2.small"
    ami                         = "${var.ami}"
    key_name                    = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids      = ["${aws_security_group.swarm-bastion.id}"]
    subnet_id                   = "${element(split(",", var.subnet_public_app), count.index)}"
    associate_public_ip_address = false

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file(var.swarm-bastion["private_key_path"])}"
    }

    provisioner "remote-exec" {
        inline = [
            "until [ -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; echo '======================== Still waiting for CLOUD-INIT finish.'; done",
            "sudo apt-get -y install unzip libltdl7",
            "sudo ln -s /usr/bin/python3 /usr/bin/python",
            "curl 'https://s3.amazonaws.com/aws-cli/awscli-bundle.zip' -o 'awscli-bundle.zip';unzip awscli-bundle.zip;./awscli-bundle/install -b ~/bin/aws",
            "curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/edge/amd64/docker-ce_17.05.0~ce-0~ubuntu-xenial_amd64.deb -o package.deb;sudo dpkg -i package.deb",
        ]
    }
    tags  {
        Name = "${terraform.env}-swarm-master-${count.index}"
        Env  = "${terraform.env}"
        Role = "swarm-node"
    }
    depends_on = [
        "aws_instance.swarm-master"
    ]
}
