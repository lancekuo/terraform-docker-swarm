data "template_file" "hostname-node" {
    template = "$${hostname}"
    count    = "${local.count_swarm_node}"

    vars {
        hostname = "${terraform.workspace}-${lower(var.project)}-node-${count.index}"
    }
}

data "template_file" "user-data-node" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = "${local.count_swarm_node}"

    vars {
        hostname = "${element(data.template_file.hostname-node.*.rendered, count.index)}"
        domain   = "${var.domain}"
    }
}
resource "aws_key_pair" "node" {
    key_name   = "${terraform.workspace}-${var.project}-${var.rsa_key_node["aws_key_name"]}"
    public_key = "${file("${path.root}${var.rsa_key_node["public_key_path"]}")}"
}
resource "aws_instance" "node" {
    count                  = "${local.count_swarm_node}"
    instance_type          = "${var.instance_type_node}"
    ami                    = "${var.aws_ami_docker}"
    key_name               = "${aws_key_pair.node.id}"
    vpc_security_group_ids = ["${aws_security_group.node.id}", "${aws_security_group.swarm-outgoing-service.id}", "${aws_security_group.logstash.id}"]
    subnet_id              = "${element(local.subnet_private_ids, count.index)}"
    monitoring             = true
    iam_instance_profile   = "${aws_iam_instance_profile.storage.name}"

    root_block_device = {
        volume_size = 20
        volume_type = "gp2"
    }

    connection {
        bastion_host        = "${aws_eip.bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.root}${var.rsa_key_node["private_key_path"]}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm join ${aws_instance.manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.manager.0.private_ip} swarm join-token -q worker)",
            "docker plugin install rexray/ebs --grant-all-permissions",
            "docker plugin install rexray/s3fs S3FS_REGION=${var.aws_region} S3FS_ENDPOINT=http://s3-${var.aws_region}.amazonaws.com S3FS_OPTIONS=iam_role=auto,url=http://s3-${var.aws_region}.amazonaws.com,curldbg --grant-all-permissions"
        ]
    }
    provisioner "remote-exec" {
        inline = [
            "docker node update --label-add azs=${count.index%length(module.vpc.availability_zones)} ${self.tags.Name}",
        ]
        connection {
            bastion_host        = "${aws_eip.bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
        }
    }
# drain and remove the node on destroy
    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker node update --availability drain ${self.tags.Name}"
        ]
        on_failure = "continue"
        connection {
            bastion_host        = "${aws_eip.bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
        }
    }

    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker swarm leave",
        ]
        on_failure = "continue"
    }

    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker node rm --force ${self.tags.Name}"
        ]
        on_failure = "continue"
        connection {
            bastion_host        = "${aws_eip.bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
        }
    }
    tags  {
        Environment = "${terraform.workspace}"
        Index       = "${count.index}"
        Name        = "${element(data.template_file.hostname-node.*.rendered, count.index)}"
        Project     = "${var.project}"
        Retention   = 365
        Role        = "node"
    }

    volume_tags  {
        Environment = "${terraform.workspace}"
        Index       = "${count.index}"
        Name        = "${element(data.template_file.hostname-manager.*.rendered, count.index)}"
        Project     = "${var.project}"
    }
    user_data  = "${element(data.template_file.user-data-node.*.rendered, count.index)}"
}
