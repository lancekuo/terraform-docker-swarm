This document describes how to build a Docker swarm mode with monitoring setup in a AWS VPC using Terraform.

The repository here has three major parts.
* Customized AMI
* Docker swarm mode
* Prometheus with Grafana

## Customzied AMI
It comes in git-submodule and uses [packer.io](https://www.packer.io/) to build our own base image in AWS. The base path for this submodule is under `.packer-docker`

Take a look at `docker.json` to see detailed configuration for the customized AMI. Briefly it takes ubnunt 16.10, docker ce_17.06, docker-machine, docker-compose and AWS CLI installed.

`docker.options` enables `experimental=true` and `insecure-registry` to `10.0.0.0/8`， `192.0.0.0/8` and `172.0.0.0/8` for testing purpose.

### Prerequisites
> Install awscli in your local machine and configure your access key secret token.

### Command
```bash
git submodule init --update
cd .packer-docker
packer build docker.json
```

###### Note 1: For building your own AMI, you need to update three parameters. `region`, `security_group_ids`, `subnet_id`.
###### Note 2: Update README.md and commit into repository when you produce a new AMI.


## Docker Swarm Mode
It spins up whole infrastructure for docker swarm in AWS.
#### Terraform Module [VPC](https://github.com/lancekuo/tf-vpc)
This module build up the fundamental of infrastructure including `VPC`, `Subnet`, `Gateway` and `Route table`.
Also, this module would build up the infrastrucutre for the specific environment and project. For example: `stg` environment for project `WRS`.

You can change/update the environment profile by using Terraform's command.
```bash
terraform env -help
```

You can change project name by update `variable.tf`
```bash
variable "project" {
    default = "WRS"
}
```
#### Terraform Module [Swarm](https://github.com/lancekuo/tf-swarm)
This is the primary module in this repository. It carries all docker swarm mode needs. Includes,

| Resource        | Purpose                          |
|-----------------|----------------------------------|
| Bastion         | With EIP                         |
| Manager         | With swarm init ready            |
| Node            | With swarm join ready            |
| Security Groups | Restrict policy                  |
| EBS             | Persist storage attached on Node |
| **ELB**         | **For Grafana:3000**             |

There are a few parameters that you will need to know.
0. `instance_per_subnet`, how many instance will be created in the same availability zone? Default is 2.
0. `swarm_manager_count`, how many `manager` will be created in total? Default is 2.
0. `swarm_node_count`, how many `node` will be created in total? Default is `instance_per_subnet` * `len(vpc.availability_zones)` - `swarm_manager_count`
###### Those parameters can be found in [VPC module](https://github.com/lancekuo/tf-vpc).

The algorism will spread EC2 instance to all subnets that created by VPC module to make sure we use every availbility zone in specific region to have best HA.

Check [here](https://github.com/lancekuo/tf-swarm/blob/master/ebs.tf) to know how to fdisk and mount to EC2 instance in first time.


#### Terraform Module [Registry](https://github.com/lancekuo/tf-registry)
This module creates private registry and store images in S3 bucket and the container runs on Bastion machine.
Default Route53_record for private registry is `{ENV}-registry.{PROJECT}.internal`.

| Resource | Purpose                          |
|----------|----------------------------------|
| S3       | Private registry run on Bastion  |
| Route53  | Point to private registry dns    |

#### Terraform Module [Backup](https://github.com/lancekuo/tf-backup)
The module to create scheduler for backup all EBS that be mounted at `/dev/xvd*` and then create tag, `DeleteOn` with days that `retention` indicated or default 14 days.
CloudWatch trigger will run the Lambda function every day at 13:00.

| Resource   | Purpose                              |
|------------|--------------------------------------|
| CloudWatch | Scheduled backup for persist storage |
| Lambda     | For backup and cleanup script        |

#### Terraform Module [Script](https://github.com/lancekuo/tf-tools)
Most beautiful feature here, it generate your ssh config file from Terraform state file.
This version comes with Bastion server settings.

### Prerequisites
> Make sure you are able to access the S3 bucket that setup in `variable.tf`
```hcl
terraform {
    backend "s3" {
        bucket = "internal"
        key    = "terraform.tfstate"
        region = "us-east-2"
    }
}
```

### Command
**Initialize Terraform**
 (one time job)
```bash
terraform get
terraform init
```
**Generate SSH key for bastion and node instance**
 (one time job)
```bash
ssh-keygen -t rsa -b 4096 -f keys/node
ssh-keygen -t rsa -b 4096 -f keys/manager
ssh-keygen -t rsa -b 4096 -f keys/bastion
```
**Import the persistent stroage**
```bash
terraform import module.registry.aws_s3_bucket.registry registry.hub.internal
terraform import module.swarm.aws_ebs_volume.storage-metric vol-034afe17b80deb0f7
```
**Apply**
```bash
terraform apply
```

### Additional
**Update your ssh config**
```bash
ruby keys/ssh_config_*.rb
```

**Teardown the infrastructure**
```bash
terraform state rm module.registry.aws_s3_bucket.registry
terraform state rm module.swarm.aws_ebs_volume.storage-metric
terraform destroy -force
```

## Prometheus and Grafana
Those docker-compose file brings you the completed stack of prometheus and Grafana.

### Command
**Build your docker image**
```bash
cd prometheus
docker-compose build
```
**Spin up**
```bash
docker stack deploy prometheus -c docker-compose.yml
```
You can find `admin` password in `docker-compose.yml` under `grafana` service.
The best dashboard that fits to us is [Docker Swarm & Container Overview](https://grafana.com/dashboards/609). Follow the screen to setup your metric source.

###### tags: amazons web service, aws, terraform, docker, docker swarm