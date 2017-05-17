resource "aws_vpc" "default" {
    cidr_block           = "${lookup(var.subnets, terraform.env)}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags  {
        Name              = "${terraform.env}-${var.project-name}"
        Env               = "${terraform.env}"
        Roles             = "vpc"
        Deployment-source = "${var.terrorform-version}"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
    tags {
        Name              = "${terraform.env}-internet-gateway"
        Env               = "${terraform.env}"
        Roles             = "internet-gateway"
        Deployment-source = "${var.terrorform-version}"
    }
}

resource "aws_nat_gateway" "default" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public1.id}"
    depends_on    = ["aws_internet_gateway.default"]
}

resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_default_route_table" "public" {
    default_route_table_id = "${aws_vpc.default.default_route_table_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
    tags {
        Name              = "public-route"
        Env               = "${terraform.env}"
        Roles             = "Router-table"
        Deployment-source = "${var.terrorform-version}"
    }
}

resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.default.id}"
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.default.id}"
    }
    tags {
        Name              = "private-route"
        Env               = "${terraform.env}"
        Roles             = "Router-table"
        Deployment-source = "${var.terrorform-version}"
    }
}

resource "aws_route_table_association" "public-route-1" {
    subnet_id      = "${aws_subnet.public1.id}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "public-app-route-1" {
    subnet_id      = "${aws_subnet.public-app1.id}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "public-app-route-2" {
    subnet_id      = "${aws_subnet.public-app2.id}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "private-route-1" {
    subnet_id      = "${aws_subnet.private1.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private-route-2" {
    subnet_id      = "${aws_subnet.private2.id}"
    route_table_id = "${aws_route_table.private.id}"
}

resource "aws_subnet" "public1" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "public_1.${terraform.env}")}"
    availability_zone       = "${var.region}a"
    map_public_ip_on_launch = true
    tags  {
        Name              = "Public-1"
        Env               = "${terraform.env}"
        Roles             = "subnet"
        Deployment-source = "${var.terrorform-version}"
        Availability-zone = "${var.region}a"
    }
    tags {
    }
}
resource "aws_subnet" "public-app1" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "app_1.${terraform.env}")}"
    availability_zone       = "${var.region}a"
    map_public_ip_on_launch = true
    tags {
        Name              = "Public-app-1"
        Env               = "${terraform.env}"
        Roles             = "subnet"
        Deployment-source = "${var.terrorform-version}"
        Availability-zone = "${var.region}a"
    }
}
resource "aws_subnet" "public-app2" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "app_2.${terraform.env}")}"
    availability_zone       = "${var.region}b"
    map_public_ip_on_launch = true
    tags {
        Name              = "Public-app-2"
        Env               = "${terraform.env}"
        Roles             = "subnet"
        Deployment-source = "${var.terrorform-version}"
        Availability-zone = "${var.region}a"
    }
}

resource "aws_subnet" "private1" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "private_1.${terraform.env}")}"
    availability_zone       = "${var.region}a"
    tags {
        Name              = "Private-1"
        Env               = "${terraform.env}"
        Roles             = "subnet"
        Deployment-source = "${var.terrorform-version}"
        Availability-zone = "${var.region}a"
    }
}
resource "aws_subnet" "private2" {
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "private_2.${terraform.env}")}"
    availability_zone       = "${var.region}b"
    tags {
        Name              = "Private-2"
        Env               = "${terraform.env}"
        Roles             = "subnet"
        Deployment-source = "${var.terrorform-version}"
        Availability-zone = "${var.region}a"
    }
}
