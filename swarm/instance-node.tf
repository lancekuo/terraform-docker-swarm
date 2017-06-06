resource "aws_key_pair" "swarm-node" {
    provider   = "aws.${var.region}"
    key_name   = "${terraform.env}-${var.region}-${var.node_aws_key_name}"
    public_key = "${file("${path.root}${var.node_public_key_path}")}"
}

data "template_file" "user-data-node" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = "${var.swarm_node_count}"

    vars {
        hostname = "${terraform.env}-${var.project}-node-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_instance" "swarm-node" {
    provider               = "aws.${var.region}"
    count                  = "${var.swarm_node_count}"
    instance_type          = "t2.small"
    ami                    = "${var.ami}"
    key_name               = "${aws_key_pair.swarm-node.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-node.id}", "${aws_security_group.swarm-outgoing-service.id}"]
    subnet_id              = "${element(split(",", var.subnet_public_app), (count.index+var.swarm_manager_count))}"

    root_block_device = {
        volume_size = 20
    }

    connection {
        bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.root}${var.node_private_key_path}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q worker)"
        ]
    }
    tags  {
        Name = "${terraform.env}-${var.project}-node-${count.index}"
        Env  = "${terraform.env}"
        Role = "swarm-node"
    }
    user_data  = "${element(data.template_file.user-data-node.*.rendered, count.index)}"
    depends_on = [
        "aws_instance.swarm-manager"
    ]
}
resource "aws_volume_attachment" "ebs_att" {
    provider     = "aws.${var.region}"
    device_name  = "/dev/xvdg"
    volume_id    = "${aws_ebs_volume.storage-metric.id}"
    instance_id  = "${element(aws_instance.swarm-node.*.id, length(aws_instance.swarm-node.*.id)-1)}"
    skip_destroy = true
    force_detach = false
}
resource "aws_ebs_volume" "storage-metric" {
    provider          = "aws.${var.region}"
    availability_zone = "${element(split(",", var.availability_zones), (length(aws_instance.swarm-node.*.id)-1+var.swarm_manager_count))}"
    size              = 100
    lifecycle = {
        ignore_changes  = "*"
        prevent_destroy = true
    }
    tags  {
        Name = "${terraform.env}-storage-metric"
        Env  = "${terraform.env}"
        Role = "storage-metric"
    }
}

resource "null_resource" "ebs_trigger" {
    triggers {
        att_id = "${aws_volume_attachment.ebs_att.id}"
    }

    provisioner "remote-exec" {
        inline = [
            "if [ -d /opt/prometheus/ ];then echo \"The folder exists.\";else sudo mkdir /opt/prometheus;echo \"Mount point created.\";fi",
#            "sudo parted /dev/xvdg --script -- mklabel msdos mkpart primary ext4 0 -1",
#            "sudo mkfs.ext4 -F /dev/xvdg1",
            "if ! grep -e \"$$(sudo file -s /dev/xvdg1|awk -F\\  '{print $8}')    /opt/prometheus\" /etc/fstab 1> /dev/null;then echo \"`sudo file -s /dev/xvdg1|awk -F\\  '{print $8}'`    /opt/prometheus    ext4    defaults,errors=remount-ro    0    0\"| sudo tee -a /etc/fstab;else echo 'Fstab has the mount point'; fi ",
            "if grep -qs '/opt/prometheus' /proc/mounts; then echo \"/opt/prometheus has mounted.\"; else sudo mount `sudo file -s /dev/xvdg1|awk -F\\  '{print $8}'` /opt/prometheus; fi",
        ]
        connection {
            bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${element(aws_instance.swarm-node.*.private_ip, length(aws_instance.swarm-node.*.private_ip)-1)}"
            private_key         = "${file("${path.root}${var.node_private_key_path}")}"
        }
    }
    provisioner "remote-exec" {
        inline = [
            "docker node update --label-add type=storage ${element(aws_instance.swarm-node.*.tags.Name, 0)}",
            "docker node update --label-add type=internal ${element(aws_instance.swarm-manager.*.tags.Name, length(aws_instance.swarm-manager.*.id)-1)}",
        ]
        connection {
            bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.swarm-manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.manager_private_key_path}")}"
        }
    }
}
