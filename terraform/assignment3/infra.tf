provider "aws" {
  region = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region =  "${var.region}"
}

###### Creates Single Internet Gateway ######
resource "aws_internet_gateway" "gw" {
  vpc_id = "vpc-4813d72f"

  tags = {
    Name = "default_ig"
  }
}

################ Create NAT gateway ##########
resource "aws_eip" "nat" {
  vpc = true
}


resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.lb.id}"
  subnet_id = "${aws_subnet.private_subnet_a.id}"
 } 
resource "aws_eip" "lb" {
  depends_on = ["aws_internet_gateway.gw"]
  vpc = true
}

##### Creates public route table ######
resource "aws_route_table" "public_routing_table" {
    vpc_id ="${var.vpc_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
        Name = "public_routing_table"
    }
}

########## Creates private route table ##########
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
  tags {
    Name = "private_routing_table"
  }
}


####### Creates 3 public Subnets ############ 
resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    #giving it 256 addresses
    cidr_block = "172.16.1.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_subneta"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.16.2.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_subnetb"
    }
}

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.16.3.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_subnetc"
    }
}

########## Creates 3 private subnets ############
resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.16.16.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.16.28.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.16.24.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}
###### Route table Association ###########

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}


######### Bastion Instance #########
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.bastion.id}"]
    tags {
        Name = "Bastion"
    }
}

################### Security Group for Bastion instance
resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow access from your current public IP address to an instance on port 22 (SSH)"
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
}

	vpc_id = "${var.vpc_id}"
}


################### Security Group for DB ##########

resource "aws_security_group" "DB" {
  name = "DB_security_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow inbound ssh traffic from VPC"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
 #	  cidr_blocks = ["0.0.0.0/0"]
      cidr_blocks = ["172.16.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "DB_security_group"
  }
}

############ DB Subnet Group #######

	resource "aws_db_subnet_group" "default" {
    name = "db_subnet_group"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
    tags {
        Name = "DB Subnet Group"
    }
}


############ RDS Instance (Relations Database Service) #####

  resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  instance_class       = "db.t2.micro"
  multi_az			   = "false"
  publicly_accessible  = "false"
  storage_type		   = "gp2"
  name                 = "maria_db"
  username             = "admin"
  password             = "password"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"

  tags {
  		Name = "RDS Instance"
	}
}



################ Security Groups ############

resource "aws_security_group" "web" {
	name = "securityweb"
	description = "Security group for the web instances that allows port 80 and 22 from instances"
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["172.16.0.0/16"]
	}
		ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["172.16.0.0/16"]
		
	}
		egress {
    	from_port = 0
    	to_port= 0
    	protocol = "-1"
    	cidr_blocks = ["0.0.0.0/0"]
  }
	
	vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "elb_security" {
	name = "securityelb"
	description = "Security group for the ELB that allows incoming ssh traffic"
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


#	vpc_id = "${var.vpc_id}"
}


############### Elastic Load Balancer #########

# Create a new load balancer

resource "aws_elb" "elb" {
  name = "terraform-elb"
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]
  security_groups = ["${aws_security_group.elb_security.id}"]

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

  instances = ["${aws_instance.instance_1.id}", "${aws_instance.instance_2.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 60
  security_groups = ["${aws_security_group.elb_security.id}"]


  tags {
    Name = "terraform_ELB"
  }
}

######## 2 instances ###############
resource "aws_instance" "instance_1" {
    ami = "ami-d2c924b2"
    associate_public_ip_address = false
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.web.id}"]
    tags {
        Name = "webserver-b"
        service = "curriculum"
    }
}

resource "aws_instance" "instance_2" {
    ami = "ami-d2c924b2"
    associate_public_ip_address = false
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.web.id}"]
    tags {
        Name = "webserver-c"
        service = "curriculum"
    }
}




