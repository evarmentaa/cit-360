variable "vpc_id" {
  description = "The VPC number"
  default = "vpc-4813d72f"
}

variable "db_password" {}

provider "aws" {
  region = "us-west-2"
}

resource "aws_subnet" "public_subnet_us_west_2a" {
	vpc_id = "${var.vpc_id}"
	cidr_block = "172.16.1.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-west-2a"
	tags = {
		Name = "Public Subnet 2a"
	}
}

resource "aws_subnet" "public_subnet_us_west_2b" {
	vpc_id = "${var.vpc_id}"
	cidr_block = "172.16.2.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-west-2b"
	tags = {
		Name = "Public Subnet 2b"
	}
}

resource "aws_subnet" "public_subnet_us_west_2c" {
	vpc_id = "${var.vpc_id}"
	cidr_block = "172.16.3.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-west-2c"
	tags = {
		Name = "Public Subnet 2c"
	}
}

resource "aws_subnet" "private_subnet_us_west_2a" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.16.16.0/22"
  availability_zone = "us-west-2a"
  tags = {
  	Name =  "Private Subnet 2a"
  }
}

resource "aws_subnet" "private_subnet_us_west_2b" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.16.28.0/22"
  availability_zone = "us-west-2b"
  tags = {
  	Name =  "Private Subnet 2b"
  }
}

resource "aws_subnet" "private_subnet_us_west_2c" {
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "172.16.24.0/22"
  availability_zone = "us-west-2c"
  tags = {
  	Name =  "Private Subnet 2c"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "gw"
  }
}


resource "aws_route_table" "public_route_table" {
	vpc_id = "${var.vpc_id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}

	tags = {
		Name = "Public route table"
	}
}


resource "aws_eip" "cit_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.cit_eip.id}"
    subnet_id = "${aws_subnet.public_subnet_us_west_2a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route_table" "private_route_table" {
    vpc_id = "${var.vpc_id}"
 	
 	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_nat_gateway.nat.id}"
	}

    tags {
        Name = "Private route table"
    }
}

resource "aws_route_table_association" "public_subnet_us_west_2a_association" {
    subnet_id = "${aws_subnet.public_subnet_us_west_2a.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "public_subnet_us_west_2b_association" {
    subnet_id = "${aws_subnet.public_subnet_us_west_2b.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "public_subnet_us_west_2c_association" {
    subnet_id = "${aws_subnet.public_subnet_us_west_2c.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "private_subnet_us_west_2a_association" {
    subnet_id = "${aws_subnet.private_subnet_us_west_2a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_subnet_us_west_2b_association" {
    subnet_id = "${aws_subnet.private_subnet_us_west_2b.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_subnet_us_west_2c_association" {
    subnet_id = "${aws_subnet.private_subnet_us_west_2c.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_db_subnet_group" "db_subnet" {
    name = "db_subnet"
    subnet_ids = ["${aws_subnet.private_subnet_us_west_2a.id}", "${aws_subnet.private_subnet_us_west_2b.id}"]
    tags {
        Name = "db_subnet"
    }
}


resource "aws_security_group" "allow_local_ssh" {
  name = "allow_local_ssh"
  vpc_id = "${var.vpc_id}"
  description = "Allow local inbound ssh traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
      cidr_blocks = ["130.166.220.26/16"]
  }

  egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db_security" {
    name = "db_security"
    vpc_id = "${var.vpc_id}"
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
    }
}

resource "aws_security_group" "web_server_security" {
    name = "web_server_security"
    vpc_id = "${var.vpc_id}"

    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
      cidr_blocks = ["130.166.220.26/16"]
    }

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["172.16.0.0/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "elb_security" {
    name = "elb_security"
    vpc_id = "${var.vpc_id}"

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.allow_local_ssh.id}"]
    subnet_id = "${aws_subnet.public_subnet_us_west_2a.id}"
    associate_public_ip_address = true
    key_name = "cit360"

    tags {
        Name = "bastion"
    }
}

resource "aws_instance" "webserver-b" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.web_server_security.id}"]
    subnet_id = "${aws_subnet.private_subnet_us_west_2b.id}"
    associate_public_ip_address = false
    key_name = "cit360"

    tags {
        Name = "webserver-b"
        Service = "curriculum"
    }
}

resource "aws_instance" "webserver-c" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.web_server_security.id}"]
    subnet_id = "${aws_subnet.private_subnet_us_west_2c.id}"
    associate_public_ip_address = false
    key_name = "cit360"

    tags {
        Name = "webserver-c"
        Service = "curriculum"
    }
}


resource "aws_db_instance" "database" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  multi_az             = "false"
  storage_type         = "gp2"
  username             = "root"
  password             = "${var.db_password}"
  db_subnet_group_name = "db_subnet"
  parameter_group_name = "default.mariadb10.0"
  vpc_security_group_ids = ["${aws_security_group.db_security.id}"]

  tags {
        Name = "MariaDB"
    }

}

resource "aws_elb" "elb" {
  name = "elb"
  subnets = ["${aws_subnet.public_subnet_us_west_2b.id}", "${aws_subnet.public_subnet_us_west_2c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.webserver-b.id}", "${aws_instance.webserver-c.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 60

  security_groups = ["${aws_security_group.elb_security.id}"]

  tags {
    Name = "aws-cit360-elb"
  }
}





