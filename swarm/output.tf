output "swarm_manager" {
    value = ["${aws_instance.swarm-manager.*.private_dns}"]
}
output "swarm_node" {
    value = ["${aws_instance.swarm-node.*.private_dns}"]
}
