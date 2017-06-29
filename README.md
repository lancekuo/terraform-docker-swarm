# Terraform with Docker Swarm mode
## What will you get?
| AWS    | Purpose                          |
|--------|----------------------------------|
| VPC    | {env} VPC                        |
| Subnets| Private, Public and Bastion      |
| GW     | Internet gateway, NAT gateway    |
| EC2    | Bastion, Mamager and Node        |
| ELB    | For Grafana:3000                 |
| EBS    | Persist storage attached on Node |
| S3     | Private registry run on Bastion  |
| Route53| Point to private registry dns    |
| CL     | Daily backup for persist storage |
| *      | Auto generated ssh config file   |
| Swarm  | Fully inited, ready to use!      |
Terraform env stg
Project wrs
## 0. Install awscli with profile setup
Install awscli and configure your access key secret token into it.
##1. Initialize Terraform module
```language
terraform get
```
##2. Initialize Terraform backend
Make sure you are able to access the S3 bucket that setup in variable.tf
```language
terraform {
    backend "s3" {
        bucket = "internal"
        key    = "terraform.tfstate"
        region = "ca-central-1"
    }
}

```
Then,
```language
terraform init
```
##3. Generate SSH key for bastion and node instance
```language
ssh-keygen -t rsa -b 4096 -f keys/node
ssh-keygen -t rsa -b 4096 -f keys/manager
ssh-keygen -t rsa -b 4096 -f keys/bastion
```
##4. Persistent stroage
Import predefined resources
```language
terraform import module.registry.aws_s3_bucket.registry registry.hub.internal
terraform import module.swarm.aws_ebs_volume.storage-metric
```
##5. Apply~~
```language
terraform apply
```

##6. Get ssh config
```language
ruby keys/ssh_config_*.rb
ssh 
```

##Additional
Teardown steps
```language
terraform state rm module.registry.aws_s3_bucket.registry
terraform state rm module.swarm.aws_ebs_volume.storage-metric
terrafrom destroy
```
