##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}


##################################################################################
# DATA
##################################################################################

# Check Ami value in a region
#aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region ap-south-1 

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = local.common_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = local.common_tags
}

resource "aws_subnet" "subnet" {
  cidr_block              = var.vpc_subnet_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = local.common_tags
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = local.common_tags
}

resource "aws_route_table_association" "rta-subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rtb.id
}

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = var.ingress_port.from_port
    to_port     = var.ingress_port.to_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = var.egress_port.from_port
    to_port     = var.egress_port.to_port
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = local.common_tags

}

# INSTANCES #
resource "aws_instance" "nginx" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  user_data = <<EOF
    #! /bin/bash
    sudo amazon-linux-extras install -y nginx1
    sudo service nginx start
    sudo rm /usr/share/nginx/html/index.html
    echo '<html><body>Hey It Works</body></html>' | sudo tee /usr/share/nginx/html/index.html
    EOF
  
    tags = local.common_tags

}

