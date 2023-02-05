#Define the provider
provider "aws" {
    region     = "us-east-1"
    access_key = "xxxxxxxxxxxxx"
    secret_key = "xxxxxxxxxxxxxxxxxxxxxxx"
}

#Create a virtual network
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    tags       = {
    Name       = "MY_VPC"
    }
}

#Create  subnet
resource "aws_subnet" "my_app-subnet" {
    tags = {
    Name = "APP_Subnet"
    }
    vpc_id                  = aws_vpc.my_vpc.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    depends_on              = [aws_vpc.my_vpc]

}

#Define routing table
resource "aws_route_table" "my_route-table" {
    tags = {
    Name = "MY_Route_table"

    }
     vpc_id = aws_vpc.my_vpc.id
}

#Associate subnet with routing table
resource "aws_route_table_association" "App_Route_Association" {
  subnet_id      = aws_subnet.my_app-subnet.id
  route_table_id = aws_route_table.my_route-table.id
}


#Create internet gateway for servers to be connected to internet

resource "aws_internet_gateway" "my_IG" {
    tags = {
        Name = "MY_IGW"
    }
     vpc_id = aws_vpc.my_vpc.id
     depends_on = [aws_vpc.my_vpc]
}

#Add default route in routing table to point to Internet Gateway

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.my_route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_IG.id
}

#Create a security group

resource "aws_security_group" "App_SG" {
    name = "App_SG"
    description = "Allow Web inbound traffic"
    vpc_id = aws_vpc.my_vpc.id
    ingress  {
        protocol = "tcp"
       from_port = 80
        to_port  = 80
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress  {
        protocol = "tcp"
        from_port = 22
        to_port  = 22
        cidr_blocks = ["0.0.0.0/0"]
}

    egress  {
        protocol = "-1"
        from_port = 0
        to_port  = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}


#create load balancer

resource "aws_elb" "test" {
  name               = "test-elb"
  internal           = false
  security_groups    = [aws_security_group.App_SG.id]
  subnets            = [aws_subnet.my_app-subnet.id]

 health_check {
   healthy_threshold   = 2
   unhealthy_threshold = 2
   timeout             = 5
   target              = "Http:80/"
   interval            =  30
}
listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}
resource "aws_lb_target_group" "testelb" {
  name     = "testelb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_launch_configuration" "temp" {
                  name                        = "temp"
                  image_id                    = "ami-0aa7d40eeae50c9a9"
                  instance_type               = "t2.micro"
                  key_name                    = "23Nov"
                  security_groups             = [aws_security_group.App_SG.id]
                  associate_public_ip_address = true
                  user_data                   = <<-EOF
              #! /bin/bash
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>HELLO Sample Webserver created<br>Shubhangi :  $(hostname)<h1>" >> /var/www/html/index.html
          EOF
}

resource "aws_autoscaling_group" "my_ASG" {

                    min_size             = 2
                    desired_capacity     = 2
                    max_size             = 5

                    health_check_type    = "ELB"
                    load_balancers = [
                       "${aws_elb.test.id}"
  ]
              launch_configuration      = aws_launch_configuration.temp.name
                enabled_metrics = [
                "GroupMinSize",
                "GroupMaxSize",
                "GroupDesiredCapacity",
                "GroupInServiceInstances",
                "GroupTotalInstances"
  ]
                metrics_granularity = "1Minute"
                vpc_zone_identifier  = [
               "${aws_subnet.my_app-subnet.id}"

  ]

}





