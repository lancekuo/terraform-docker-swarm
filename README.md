# Terraform with Docker Swarm mode
## Import Resources
Import predefined resources before you `terraform apply`
- module.registry.aws_s3_bucket.registry registry.hub.internal
- module.swarm.aws_ebs_volume.storage-metric