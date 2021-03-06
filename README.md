This document describes how to build a Docker swarm  with monitoring setup in a AWS VPC using Terraform.

The repository here has three major parts.
* Customized AMI
* Docker swarm mode
* Prometheus with Grafana
* Examples
  * Logging
  * Reverse proxy
  * Dynamic storage
```
              ┌──────────────────────────────┐                 
              │ Docker VPC                   │                 
              │     ┌───────────────────┐    │                 
              │ ┌──▶│      Manager 0    │    │                 
              │ │   └───────────────────┘    │                 
              │ │   ┌───────────────────┐    │                 
 ┌───┐  ┌───┐ │ ├──▶│      Manager 1    │    │                 
 │ R │  │ E │ │ │   └───────────────────┘    │                 
 │ 5 │─▶│ L │─┼─┤   ┌───────────────────┐    │                 
 │ 3 │  │ B │ │ ├──▶│       Node 0      │──┐ │                 
 └───┘  └───┘ │ │   └───────────────────┘  │ │                 
              │ │   ┌───────────────────┐  │ │                 
              │ ├──▶│       Node 1      │  │ │ ┌──────────────┐
              │ │   └───────────────────┘  └─┼▶│ EBS Metric   │
              │ │   ┌───────────────────┐    │ └──────────────┘
              │ └──▶│       Node 2      │    │ ┌──────────────┐
              │     └───────────────────┘  ┌─┼▶│ S3 Registry  │
              │     ┌───────────────────┐  │ │ └──────────────┘
              │     │      Bastion      │──┘ │                 
              │     └─────┬─────────────┘    │                 
              └───────────┼──────────────────┘                 
 ┌───┐                    │                                    
 │ R │            .───────▼───────────.                        
 │ 5 │──────────▶(  Private Registry   )                       
 │ 3 │            `───────────────────'                        
 └───┘                                                         
```



## Customzied AMI

It comes in git-submodule and uses [packer.io](https://www.packer.io/) to build our own base image in AWS. The base path for this submodule is under `.packer-docker`

Take a look at `docker.json` to see detailed configuration for the customized AMI. Briefly it takes ubnunt 18.04, docker ce_18.06, docker-compose, cloud-init for attached Ebs and AWS CLI installed.

`docker.options` enables `metrics`, `experimental=true` and `insecure-registry` to `10.0.0.0/8`， `192.0.0.0/8` and `172.0.0.0/8` for testing purpose.

### Prerequisites

> Install awscli in your host machine and configure your access key secret token.

### Command
```bash
git submodule update --init
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
terraform workspace -help
```

You can change `project` name and `region` by update `variable.tf`
```bash
variable "project" {
    default = "SampleProject"
}
variable "region" {
    default = "us-east-1"
}
```
#### Terraform - Swarm

This is the primary module in this repository. It carries all docker swarm mode needs. Includes,

| Resource        | Purpose                          |
|-----------------|----------------------------------|
| Bastion         | With EIP                         |
| Manager         | With swarm init ready            |
| Node            | With swarm join ready            |
| Security Groups | Restrict policy                  |
| EBS             | Persist storage attached on Node |
| IAM             | IAM Role for Instance Profile    |
| **ELB**         | **For Grafana:3000**             |
| **ELB**         | **For Kibana:5601**              |
| **R53**         | **For Logstash:5000/udp**        |

There are a few parameters that you will need to know.
1. `count_instance_per_az`, how many instance will be created in the same availability zone? Default is 2.
1. `count_swarm_manager`, how many `manager` will be created in total? Default is 3 for minimal HA requirement.
1. `count_swarm_node`, how many `node` will be created in total? Default is `count_instance_per_az` * `len(vpc.availability_zones)` - `count_swarm_manager`
###### Those parameters can be found in [VPC module](https://github.com/lancekuo/tf-vpc).

The simple algorithm will spread EC2 instance to all subnets that created by VPC module as much as possible to make sure we use every availbility zone in specific region to have best high availability.

##### IAM and Instance Profile

This will create a Instance Profile under `storage-node` IAM Role. This profile will be attached to each one of managers and workers node.

The `storage-node` comes with two major permissions,

- Ebs management
- S3 management

#### Terraform Module [Registry](https://github.com/lancekuo/tf-registry)

This module creates private registry and store images in S3 bucket and the container runs on Bastion machine.
Default Route53_record for private registry is `{ENV}-registry.{PROJECT}.internal`.

| Resource | Purpose                          |
|----------|----------------------------------|
| S3       | Private registry run on Bastion  |
| Route53  | Point to private registry dns    |

#### Important Note
> Add `/docker` folder under root of the bucket for registry, this is the bug of registry.
>
> This was added into terraform script, the script would create bucket and folder at the same time once enabled.
```hcl
Bucket: registry.hub.internal
        /docker
```

#### Terraform Module [Backup](https://github.com/lancekuo/tf-backup)
The module to create scheduler for backup all EBS that be mounted at `/dev/xvd*` and then create tag, `DeleteOn` with the days that tag , `retention` indicated or default 14 days.
CloudWatch trigger will run the Lambda function every day at 08:00 UTC.

Lambda script was wrote in Go for myself practice.

| Resource   | Purpose                              |
|------------|--------------------------------------|
| CloudWatch | Scheduled backup for persist storage |
| Lambda     | For backup and cleanup script        |

#### Terraform Module [Script](https://github.com/lancekuo/tf-tools)
Most beautiful feature, it generate your ssh config file from Terraform state file.
This version comes with Bastion server settings.

### (Optional)
> Make sure you are able to access the S3 bucket that setup in `variable.tf` if you're using terraform backend feature for storing state file.
```hcl
terraform {
    backend "s3" {
        bucket = "internal"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}
```

### Command

**Initialize Terraform**
 (one time job)
```bash
terraform init
terraform get
```
**Generate SSH key for bastion and node instance**
 (one time job)
```bash
ssh-keygen -q -t rsa -b 4096 -f keys/node -N ''
ssh-keygen -q -t rsa -b 4096 -f keys/manager -N ''
ssh-keygen -q -t rsa -b 4096 -f keys/bastion -N ''
```
**Import the persistent stroage**

```bash
terraform import module.registry.aws_s3_bucket.registry registry.hub.internal
terraform import module.swarm.aws_ebs_volume.storage-metric vol-034afe17b80deb0f7
```
**Modify variable from default.tfvars.example**

```bash
cp default.tfvars.exmaple default.auto.tfvars
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
terraform state rm module.registry.aws_s3_bucket_object.docker
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

## Docker Stack for Logging

Those docker-compose file brings you the completed stack of ELK 6.2.

### Command
**Build your docker image**
```bash
cd elk
docker-compose build
```
**Spin up**
```bash
docker stack deploy elk -c docker-compose.yml
```
**Docker Logging Driver**
```bash
docker run --rm -it \
             --log-driver gelf \
             --log-opt gelf-address=udp://stg-logstash.sampleproject.internal:5000 \
             busybox echo This is my message.
```
Or
```bash
docker service create \
             --name temp_service \
             --network elk_logging \
             --log-driver gelf \
             --log-opt gelf-address=udp://stg-logstash.sampleproject.internal:5000 \
             busybox echo This is my message.
```
Docker log driver document (https://docs.docker.com/engine/admin/logging/gelf/#gelf-options)



## Docker Stack for Docker Flow Proxy

```bash
cd dfproxy
docker stack deploy app -c docker-compose.yml
```



## Docker Stack for Dynamic Storage

The specified docker volume is necessary here if the service/stack requires persistent storage.

Here is the example,

```yaml
version: "3.5"
volumes:
    data-rexray-ebs:
        name: 'rexray_ebs_{{.Service.Name}}-{{.Task.Slot}}'
        driver: rexray/ebs
        driver_opts:
            size: 29
            snapshotID: ""
            volumeType: "gp2"    #io1 needs to come with iops
            iops: 0              #default 100 in gp2
            availabilityZone: "" #No quick solution for changing azs in docker compose
            encrypted: "false"
            encryptionKey: "test"
            force: "false"
            fsType: "ext4"

    data-rexray-s3fs:
        name: 'rexray_s3fs_{{.Service.Name}}-{{.Task.Slot}}'
        driver: rexray/s3fs
services:
    sameple:
        image: "busybox"
        command: "tail -f /dev/null"
        volumes:
           - data-rexray-ebs:/data
        deploy:
            placement:
                constraints:
                    - node.labels.azs == 0
```

### Known issues

1. There is no easy way to get all availability zone for user to pick up and use it in their docker-compose file
2. In the practice, every deployment command should run in `bastion` machine and it is located in `{regionName}-{index}a`, so we can append `- node.labels.azs == 0` in services section
3. Don't know what to set in configuration file? Take a look at [here](https://github.com/rexray/rexray/issues/733)



###### tags: amazons web service, aws, terraform, docker, docker swarm, ELK, HAProxy

######  Deprecated: ebs.tf, take a look [here](https://github.com/lancekuo/terraform-docker-swarm/blob/ed4d48ac2a552e8ff3baaf19d0a602154a48a76f/ebs.tf) is you need old school way to handle EBS.

