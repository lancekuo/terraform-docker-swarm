output "swarm_manager" {
    value = ["${aws_instance.swarm-manager.*.public_dns}"]
}
output "swarm_node" {
    value = ["${aws_instance.swarm-node.*.private_dns}"]
}
