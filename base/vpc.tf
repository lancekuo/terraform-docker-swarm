resource "aws_vpc" "default" {
    cidr_block           = "${lookup(var.subnets, terraform.env)}"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags  {
        Name              = "${terraform.env}-${var.project-name}"
        Env               = "${terraform.env}"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
    tags {
        Name              = "${terraform.env}-internet-gateway"
        Env               = "${terraform.env}"
    }
}

resource "aws_nat_gateway" "default" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.private.0.id}"
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
    }
}

resource "aws_subnet" "public" {
    count                   = "${var.subnet-on-public}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "public_${count.index+1}.${terraform.env}")}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags  {
        Name              = "Public-1"
        Env               = "${terraform.env}"
    }
    tags {
    }
}
resource "aws_subnet" "public-app" {
    count                   = "${var.subnet-per-zone}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "app_${count.index+1}.${terraform.env}")}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name              = "Public-app${count.index}"
        Env               = "${terraform.env}"
    }
}

resource "aws_subnet" "private" {
    count                   = "${var.subnet-per-zone}"
    vpc_id                  = "${aws_vpc.default.id}"
    cidr_block              = "${lookup(var.subnets, "private_${count.index+1}.${terraform.env}")}"
    availability_zone       = "${element(data.aws_availability_zones.azs.names, count.index)}"
    map_public_ip_on_launch = true
    tags {
        Name              = "Private${count.index}"
        Env               = "${terraform.env}"
    }
}

resource "aws_route_table_association" "public-route" {
    count = "${var.subnet-on-public}"
    subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "public-app-route" {
    count = "${var.subnet-per-zone}"
    subnet_id      = "${element(aws_subnet.public-app.*.id, count.index)}"
    route_table_id = "${aws_default_route_table.public.id}"
}

resource "aws_route_table_association" "private-route" {
    count = "${var.subnet-per-zone}"
    subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
    route_table_id = "${aws_route_table.private.id}"
}
