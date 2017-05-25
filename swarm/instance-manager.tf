resource "aws_key_pair" "swarm-manager" {
    key_name   = "${terraform.env}-${var.region}-${var.swarm-manager["key_name"]}"
    public_key = "${file("${path.module}/script/${var.swarm-manager["public_key_path"]}")}"
}

data "template_file" "user-data-master" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count = "${var.swarm_manager_count}"

    vars {
        hostname = "${terraform.env}-manager-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_instance" "swarm-manager" {
    count                       = "${var.swarm_manager_count}"
    instance_type               = "t2.small"
    ami                         = "${var.ami}"
    key_name                    = "${aws_key_pair.swarm-manager.id}"
    vpc_security_group_ids      = ["${aws_security_group.swarm-node.id}", "${aws_security_group.swarm-manager.id}"]
    subnet_id                   = "${element(split(",", var.subnet_public_app), count.index)}"

    root_block_device = {
        volume_size = 20
    }

    connection {
        bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.module}/script/${var.swarm-bastion["private_key_path"]}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.module}/script/${var.swarm-manager["private_key_path"]}")}"
    }

    provisioner "remote-exec" {
        inline = [" if [ ${count.index} -eq 0 ]; then sudo docker swarm init; else sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q manager); fi"]
    }
    tags  {
        Name = "${terraform.env}-swarm-manager-${count.index}"
        Env  = "${terraform.env}"
        Role = "swarm-manager"
    }
    user_data = "${element(data.template_file.user-data-master.*.rendered, count.index)}"
    depends_on = [
        "aws_instance.swarm-bastion"
    ]
}
