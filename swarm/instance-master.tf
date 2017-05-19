resource "aws_instance" "swarm-master" {
    count                       = "${var.swarm_master_count}"
    instance_type               = "t2.small"
    ami                         = "${var.ami}"
    key_name                    = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids      = ["${aws_security_group.swarm-node.id}", "${aws_security_group.swarm-master.id}"]
    subnet_id                   = "${element(split(",", var.subnet_public_app), count.index)}"

    connection {
        bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file(var.swarm-bastion["private_key_path"])}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file(var.swarm-bastion["private_key_path"])}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm init"
        ]
    }
    tags  {
        Name = "${terraform.env}-swarm-master-${count.index}"
        Env  = "${terraform.env}"
        Role = "swarm-master"
    }
    depends_on = [
        "aws_instance.swarm-bastion"
    ]
}
