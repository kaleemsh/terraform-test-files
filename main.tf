# create vpc
resource "aws_vpc" "terra-vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "main-terra-vpc"
  }
}


# create subnets
resource "aws_subnet" "subnet-1a-main" {
  vpc_id     = aws_vpc.terra-vpc.id
  cidr_block = "${var.subnet-1a-cidr-block}"

  tags = {
    Name = "subnet-1a-main"
  }
  availability_zone = "${var.subnet-1a}"
  map_public_ip_on_launch = "true"
}


resource "aws_subnet" "subnet-1b-main" {
  vpc_id     = aws_vpc.terra-vpc.id
  cidr_block = "10.10.2.0/24"

  tags = {
    Name = "subnet-1b-main"
  }
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

}

resource "aws_subnet" "subnet-1c-main" {
  vpc_id     = aws_vpc.terra-vpc.id
  cidr_block = "10.10.3.0/24"

  tags = {
    Name = "subnet-1c-main"
  }
  availability_zone = "ap-south-1c"

}

# Launching instance with subnet_id

resource "aws_instance" "webapp-1a" {
  ami           = "${var.ami}"
  instance_type = "${var.instance-type}"

  tags = {
    Name = "webapp-1a"
  }
  subnet_id = aws_subnet.subnet-1a-main.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = "${var.key-name}"
}

resource "aws_instance" "webapp-1b" {
  ami           = "${var.ami}"
  instance_type = "${var.instance-type}"

  tags = {
    Name = "webapp-1b"
  }
  subnet_id = aws_subnet.subnet-1b-main.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = "${var.key-name}"
}

resource "aws_instance" "webapp-1b-1" {
  count = "${var.desired-machine-count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance-type}"

  tags = {
    Name = "webapp-1b-1"
  }
  subnet_id = aws_subnet.subnet-1b-main.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = "${var.key-name}"
}

# creating security group

resource "aws_security_group" "allow_port80" {
  name        = "allow_port80"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.terra-vpc.id

  ingress {
    description      = "allow inbound traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# create internet gateway
resource "aws_internet_gateway" "webapp-Ig" {
  vpc_id = aws_vpc.terra-vpc.id

  tags = {
    Name = "webapp-ig"
  }
}

# create route table
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.terra-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-Ig.id
  }

  
  tags = {
    Name = "terra-public-RT"
  }
}
  

# Attaching route table association
resource "aws_route_table_association" "RT-asso-1a" {
  subnet_id      = aws_subnet.subnet-1a-main.id
  route_table_id = aws_route_table.public_RT.id
  
}

resource "aws_route_table_association" "RT-asso-1b" {
  subnet_id      = aws_subnet.subnet-1b-main.id
  route_table_id = aws_route_table.public_RT.id
  
}

# target group creation
resource "aws_lb_target_group" "webapp-target-group" {
  name     = "webapp-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terra-vpc.id
}

# attaching target-group
resource "aws_lb_target_group_attachment" "webapp1a-target-group-attachment" {
  target_group_arn = aws_lb_target_group.webapp-target-group.arn
  target_id        = aws_instance.webapp-1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp1b-target-group-attachment" {
  target_group_arn = aws_lb_target_group.webapp-target-group.arn
  target_id        = aws_instance.webapp-1b.id
  port             = 80
}

#resource "aws_lb_target_group_attachment" "webapp1b-1-target-group-attachment" {
  #target_group_arn = aws_lb_target_group.webapp-target-group.arn
  #target_id        = aws_instance.webapp-1b-1.id
  #port             = 80
#}

resource "aws_lb_target_group_attachment" "webapp-4-target-group-attachment" {
  count = length(aws_instance.webapp-1b-1)
  target_group_arn = aws_lb_target_group.webapp-target-group.arn
  target_id        = aws_instance.webapp-1b-1[count.index].id
  port             = 80
}
# this security group is for lb
resource "aws_security_group" "allow_port80_lb" {
  name        = "allow_port80_lb"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.terra-vpc.id

  ingress {
    description      = "allow inbound traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}



# creating load-balancer
#resource "aws_lb" "webapp-lb" {
  #name               = "webapp-lb"
  #internal           = false
  #load_balancer_type = "application"
  #security_groups    = [aws_security_group.allow_port80_lb.id]
  #subnets            = [aws_subnet.subnet-1a-main.id,aws_subnet.subnet-1b-main.id]


  #tags = {
    #Environment = "production"
    #Name = "webapp"
  #}
#}

# adding listner
#resource "aws_lb_listener" "webapp-listner" {
  #load_balancer_arn = aws_lb.webapp-lb.arn
  #port              = "80"
  #protocol          = "HTTP"
  
  #default_action {
    #type             = "forward"
    #target_group_arn = aws_lb_target_group.webapp-target-group.arn
  #}
#}


# creating ELB-load-balancer
#resource "aws_elb" "webapp-elb" {
  #name               = "webapp-lb-tf"
  #internal           = false
  #load_balancer_type = "application"
  #security_groups    = [aws_security_group.allow_port80_lb.id]
  #subnets            = [aws_subnet.subnet-1a-main.id,aws_subnet.subnet-1b-main.id]


  #tags = {
    #Environment = "production"
    #Name = "webapp"
  #}


  #health_check {
    #healthy_threshold   = 2
    #unhealthy_threshold = 2
    #timeout             = 3
    #target              = "HTTP:80/"
    #interval            = 30
  #}

  #listener {
    #instance_port     = 80
    #instance_protocol = "http"
    #lb_port           = 80
    #lb_protocol       = "http"
  #}
#}

# aws_launch configuration
#resource "aws_launch_configuration" "web" {
  #name_prefix   = "web-"

  #image_id      = "ami-052cb5e834ea3eece"
  #instance_type = "t2.micro"
  #key_name = "central ansible"
  #security_groups = [ aws_security_group.allow_port80.id ]
  #associate_public_ip_address = true
  
  #lifecycle {
    #create_before_destroy = false
  #}
#}

# aws_auto scaling 
#resource "aws_autoscaling_group" "web-as" {
  #name                      = "aws-auto"
  #max_size                  = 5
  #min_size                  = 2
  #desired_capacity          = 2

  #health_check_type         = "ELB"
  
  
  #load_balancers            = [aws_elb.webapp-elb.id]
  #launch_configuration      = aws_launch_configuration.web.id
  #vpc_zone_identifier       = [aws_subnet.subnet-1a-main.id,aws_subnet.subnet-1b-main.id]

#}


  










  




