provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "instance-pro" {
    ami =  "ami-0022f774911c1d690"
    instance_type = "t2.micro"
    tags = {
      owner = "kokou"
      Name = "school-site"
    }
  
}

resource "aws_instance" "instance-pro1" {
    ami =  "ami-0022f774911c1d690"
    instance_type = "t2.micro"
    tags = {
      owner = "kokou"
      Name = "school-site"
    }
  
}

resource "aws_vpc" "school-site-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "school-site-vpc"
  }
  
}
# interet gateway for vpc
resource "aws_internet_gateway" "school-site-igw" {
    vpc_id = aws_vpc.school-site-vpc.id
    tags = {
      "Name" = "school-site-igw"
    }
    
}

# Route table for private subnet
resource "aws_route_table" "school-sitePrivateRtable" {
    vpc_id = aws_vpc.school-site-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.Nat.id
    }
    

    tags = {
      "Name" = "school-sitePrivateRtable"
    }
  
}

# Route table for public subnet
resource "aws_route_table" "school-sitePubrt" {
    vpc_id = aws_vpc.school-site-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.school-site-igw.id
    }

}

resource "aws_subnet" "school-site-puSubnet1" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"

  tags = {
    Name = "school-site-puSubnet1"
  }
}

resource "aws_subnet" "school-site-puSubnet2" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "school-site-puSubnet2"
  }
}

# association between public subnet and public route table
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.school-site-puSubnet1.id
    route_table_id = aws_route_table.school-sitePubrt.id
}
    
resource "aws_subnet" "school-site-privateSubnet1" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = "false"
  availability_zone = "us-east-1a"

  tags = {
    Name = "school-site-privateSubnet1"
  }
}

resource "aws_subnet" "school-site-privateSubnet2" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone = "us-east-1a"

  tags = {
    Name = "school-site-privateSubnet2"
  }
}

resource "aws_subnet" "school-site-privateSubnet3" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.5.0/24"
  map_public_ip_on_launch = "false"
  availability_zone = "us-east-1b"

  tags = {
    Name = "school-site-privateSubnet3"
  }
}

resource "aws_subnet" "school-site-privateSubnet4" {
  vpc_id     = aws_vpc.school-site-vpc.id
  cidr_block = "10.0.6.0/24"
  map_public_ip_on_launch = "false"
  availability_zone = "us-east-1b"

  tags = {
    Name = "school-site-privateSubnet3"
  }
}

# association between private subnet and private route table
resource "aws_route_table_association" "private1" {
    subnet_id = aws_subnet.school-site-privateSubnet1.id
    route_table_id = aws_route_table.school-sitePrivateRtable.id
}

# Elastic ip for NAT gateway
resource "aws_eip" "nat_eip" {
    vpc = true
    depends_on = [
      aws_internet_gateway.school-site-igw
    ]
    tags = {
      "Name" = "nat_gateway EIP"

    }
}

# nat gateway for vpc
resource "aws_nat_gateway" "Nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.school-site-puSubnet1.id
    tags = {
      "Name" = "school-site Nat gateway"
    }
  
}

resource "aws_launch_template" "school-siteLt" {
  name_prefix   = "school-site"
  image_id      = "ami-0022f774911c1d690"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "school" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2

  launch_template {
    id      = aws_launch_template.school-siteLt.id
    version = "$Latest"
  }
}

# creating security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow tls inbound traffic"
  vpc_id      = aws_vpc.school-site-vpc.id

  ingress {
    description      = "tls from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.school-site-vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}