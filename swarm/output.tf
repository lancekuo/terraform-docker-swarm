output "swarm_master" {
    value = ["${aws_instance.swarm-master.*.public_dns}"]
}
output "swarm_node" {
    value = ["${aws_instance.swarm-node.*.private_dns}"]
}
