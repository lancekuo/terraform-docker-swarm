resource "aws_key_pair" "swarm-node" {
    key_name   = "${terraform.env}-${var.region}-${var.swarm-node["key_name"]}"
    public_key = "${file("${path.module}/script/${var.swarm-node["public_key_path"]}")}"
}

data "template_file" "user-data-node" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count = "${var.swarm_node_count}"

    vars {
        hostname = "${terraform.env}-node-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_instance" "swarm-node" {
    count                       = "${var.swarm_node_count}"
    instance_type               = "t2.small"
    ami                         = "${var.ami}"
    key_name                    = "${aws_key_pair.swarm-node.id}"
    vpc_security_group_ids      = ["${aws_security_group.swarm-node.id}"]
    subnet_id                   = "${element(split(",", var.subnet_public_app), (count.index+var.swarm_manager_count))}"

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
        private_key         = "${file("${path.module}/script/${var.swarm-node["private_key_path"]}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q worker)"
        ]
    }
    tags  {
        Name = "${terraform.env}-swarm-node-${count.index}"
        Env  = "${terraform.env}"
        Role = "swarm-node"
    }
    user_data = "${element(data.template_file.user-data-node.*.rendered, count.index)}"
    depends_on = [
        "aws_instance.swarm-manager"
    ]
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.storage-metric.id}"
  instance_id = "${element(aws_instance.swarm-node.*.id, length(aws_instance.swarm-node.*.id)-1)}"
}
resource "aws_ebs_volume" "storage-metric" {
  availability_zone = "${element(split(",", var.availability_zones), (length(aws_instance.swarm-node.*.id)-1+var.swarm_manager_count))}"
  size              = 50
}
