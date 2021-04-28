############ VPC creation ###################################################

resource "aws_vpc" "terraform" {
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = "172.16.0.0/16"
    tags = {
      "Name" = "terraform"
    }
  
}

########### subnet creation #################################################

resource "aws_subnet" "my-tf-sub1" {
    vpc_id = aws_vpc.terraform.id
    cidr_block = "172.16.0.0/18"
    map_public_ip_on_launch = true
    tags = {
      Name = "my-tf-sub1-public"
    }
}

resource "aws_subnet" "my-tf-sub2" {
    vpc_id = aws_vpc.terraform.id
    cidr_block = "172.16.64.0/18"
    map_public_ip_on_launch = true
    tags = {
      Name = "my-tf-sub2-public"
    }
}

resource "aws_subnet" "my-tf-sub3" {
    vpc_id = aws_vpc.terraform.id
    cidr_block = "172.16.128.0/18"
    map_public_ip_on_launch = false
    tags = {
      Name = "my-tf-sub3-private"
    }
}

########### Internet gateway and NAT gateway ###############################

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.terraform.id
  tags = {
    Name = "tf-igw"
  }
}

resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "tf-nat-gw" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.my-tf-sub2.id
    tags = {
      Name = "tf-nat-gw"
    }
}

########### Key generation ################################################

resource "aws_key_pair" "keypair" {
    key_name = "penguinzz"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdeIOxR3TTzPDFXbBIYp7EqNDn6m4KrVzluHkpS8bLFeQqZCK548H5GjGagwoQUmibxx9VL39isnLxcOy3a0J8BfiJ2e4f3dSF5kp6OeyVTiK7MRxaacPmltTB/5YFLtaWBaMbF6UxOHmLS0N/wDPEReHyEZJgpyO5/410rq5t9WEuAza0x2Ny50eILB/T6g6/j2ZELjogXWHMjo+IA3T+f7dB6IsvvbZ/vvnj54UKR7OkxoxacYU5bVzZht/9IA6PqFgFCgSVq2QmxTczHn4uN4jyORQZVaInlUsjwg8fizytXifJTIr6oQSXIv+zTfEexIOeRr8zuqXnMKRN8/7L ec2-user@ip-172-31-2-165.us-east-2.compute.internal"

}

########### Route table creation ##########################################

resource "aws_route_table" "tf-rt-public" {
    vpc_id = aws_vpc.terraform.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.tf-igw.id
    } 
    tags = {
      Name = "tf-rt-public"
    }
}

resource "aws_route_table" "tf-rt-private" {
    vpc_id = aws_vpc.terraform.id
    route {
      cidr_block = "0.0.0.0/0" 
      gateway_id = aws_nat_gateway.tf-nat-gw.id
    }
    tags = {
      Name = "tf-rt-private"
    }
}

########### Route table association #######################################

resource "aws_route_table_association" "tf-public1" {
    subnet_id = aws_subnet.my-tf-sub1.id
    route_table_id = aws_route_table.tf-rt-public.id
}

resource "aws_route_table_association" "tf-public2" {
    subnet_id = aws_subnet.my-tf-sub2.id
    route_table_id = aws_route_table.tf-rt-public.id
}

resource "aws_route_table_association" "tf-private" {
    subnet_id = aws_subnet.my-tf-sub3.id
    route_table_id = aws_route_table.tf-rt-private.id
  
}

########## Security group Creation ########################################

resource "aws_security_group" "tf_bastion" {
    name = "tf_bastion"
    description = "allows 22 port only"
    vpc_id = aws_vpc.terraform.id

    ingress {
      description = "Allowing SSH Connection"
      cidr_blocks = ["0.0.0.0/0"]
      from_port = "22"
      protocol = "tcp"
      to_port = "22"
    }

    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = "0"
      to_port = "0"
      protocol = "-1"
    } 
    tags = {
      Name = "tf_bastion"
    }
}

resource "aws_security_group" "tf_instance" {
    name = "tf_instance"
    description = "Security group for instance:allowing port 80"
    vpc_id = aws_vpc.terraform.id
    ingress {
      from_port = "22"
      to_port = "22"
      protocol = "tcp"
      security_groups = [ aws_security_group.tf_bastion.id ]
    }

    ingress {
      from_port   = "80"
      to_port     = "80"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = "0"
      protocol = "-1"
      to_port = "0"
    } 
    tags = {
      Name = "tf_instance"
    }
}

resource "aws_security_group" "tf_private" {
    name = "tf_private"
    description = "Security group for instance:allowing port 80"
    vpc_id = aws_vpc.terraform.id
    ingress {
      from_port = "22"
      to_port = "22"
      protocol = "tcp"
      security_groups = [ aws_security_group.tf_bastion.id ]
    }

    ingress {
      from_port   = "3306"
      to_port     = "3306"
      protocol    = "tcp"
      security_groups = [ aws_security_group.tf_instance.id ]
    }

    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = "0"
      protocol = "-1"
      to_port = "0"
    } 
    tags = {
      Name = "tf_private"
    }
}

####### Instance Creation ################################################

resource "aws_instance" "bastion_instance" {
    ami = "ami-05d72852800cbf29e"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my-tf-sub1.id
    key_name = aws_key_pair.keypair.key_name
    vpc_security_group_ids = [ aws_security_group.tf_bastion.id ]
    tags = {
      Name = "bastion_instance"
    }
}

resource "aws_instance" "main_instance" {
    ami = "ami-05d72852800cbf29e"
    instance_type = "t2.micro"
    key_name = aws_key_pair.keypair.key_name
    user_data = file("apache-install.sh")
    subnet_id = aws_subnet.my-tf-sub2.id
    vpc_security_group_ids = [ aws_security_group.tf_instance.id ]
    tags = {
      Name = "main_instance"
    }
}

resource "aws_instance" "private_instance" {
    ami = "ami-05d72852800cbf29e"
    instance_type = "t2.micro"
    key_name = aws_key_pair.keypair.key_name
    user_data = file("mariadb-install.sh")
    subnet_id = aws_subnet.my-tf-sub3.id
    vpc_security_group_ids = [ aws_security_group.tf_private.id ]
    tags = {
      Name = "private_instance"
    }

}
