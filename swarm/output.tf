output "swarm_manager" {
    value = ["${aws_instance.swarm-manager.*.private_dns}"]
}
output "swarm_node" {
    value = ["${aws_instance.swarm-node.*.private_dns}"]
}
output "bastion_public_ip" {
    value = "${join(",", aws_instance.swarm-bastion.*.public_ip)}"
}
output "bastion_private_ip" {
    value = "${join(",", aws_instance.swarm-bastion.*.private_ip)}"
}
output "swarm_bastion_private_key_path" {
    value = "${var.swarm-bastion["private_key_path"]}"
}
