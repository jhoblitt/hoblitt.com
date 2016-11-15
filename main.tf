provider "aws" {
    region = "${var.aws_default_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_key_pair" "github" {
    key_name = "hoblitt-com"
    public_key = "${file("/home/jhoblitt/.ssh/id_rsa_github.pub")}"
}

#resource "aws_kms_key" "hc" {
#	description = "KMS key 1"
#    deletion_window_in_days = 30
#}

resource "aws_vpc" "hoblitt-com" {
    cidr_block = "192.168.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "hoblitt-com"
    }
}

resource "aws_internet_gateway" "hoblitt-com" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"

    tags {
        Name = "hoblitt-com"
    }
}

resource "aws_subnet" "hoblitt-com" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    cidr_block = "192.168.42.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${var.aws_default_region}c"

    tags {
        Name = "hoblitt-com"
    }
}

resource "aws_route_table" "hoblitt-com" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.hoblitt-com.id}"
    }

    tags {
        Name = "hoblitt-com"
    }
}

resource "aws_main_route_table_association" "hoblitt-com" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    route_table_id = "${aws_route_table.hoblitt-com.id}"
}

resource "aws_network_acl" "hoblitt-com" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    subnet_ids = ["${aws_subnet.hoblitt-com.id}"]

    ingress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
        action = "allow"
    }

    egress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
        action = "allow"
    }

    tags {
        Name = "hoblitt-com"
    }
}

resource "aws_eip" "hoblitt-com" {
    vpc = true
    instance = "${aws_instance.web.id}"
}

resource "aws_security_group" "hoblitt-com-ssh" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    name = "hoblitt-com-ssh"
    description = "allow external ssh"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "hoblitt-com-ssh"
    }
}

resource "aws_security_group" "hoblitt-com-http" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    name = "hoblitt-com-http"
    description = "allow external http/https"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "hoblitt-com-http"
    }
}

resource "aws_security_group" "hoblitt-com-mail" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    name = "hoblitt-com-mail"
    description = "allow external smtp/smtps"

	# postfix
    ingress {
        from_port = 25
        to_port = 25
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # inbound relay from duocircle
    ingress {
        from_port = 2525
        to_port = 2525
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 587
        to_port = 587
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

	# dovecot
    ingress {
        from_port = 143
        to_port = 143
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 993
        to_port = 993
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # pigeonhole
    ingress {
        from_port = 4190
        to_port = 4190
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "hoblitt-com-http"
    }
}

resource "aws_security_group" "hoblitt-com-icmp" {
    vpc_id = "${aws_vpc.hoblitt-com.id}"
    name = "hoblitt-com-icmp"
    description = "allow icmp"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8
        to_port = 8
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 8
        to_port = 8
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "hoblitt-com-icmp"
    }
}

resource "aws_security_group" "hoblitt-com-internal" {
  vpc_id      = "${aws_vpc.hoblitt-com.id}"
  name        = "hoblitt-com-internal"
  description = "allow all VPC internal traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.hoblitt-com.cidr_block}"]
  }

  # allow all output traffic from the VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "hoblitt-com-internal"
  }
}

resource "aws_instance" "web" {
    ami = "ami-d2c924b2"
    instance_type = "t2.small"
    #availability_zone = "${var.aws_default_region}c"
    instance_initiated_shutdown_behavior = "stop"
    subnet_id = "${aws_subnet.hoblitt-com.id}"
    vpc_security_group_ids = [
        "${aws_security_group.hoblitt-com-internal.id}",
        "${aws_security_group.hoblitt-com-icmp.id}",
        "${aws_security_group.hoblitt-com-ssh.id}",
        "${aws_security_group.hoblitt-com-http.id}",
        "${aws_security_group.hoblitt-com-mail.id}",
    ]
    key_name = "${aws_key_pair.github.id}"

    root_block_device = {
        volume_type = "gp2"
        volume_size = 50
        delete_on_termination = false
    }

    tags {
        Name = "hoblitt-com"
    }
}
