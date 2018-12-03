# Define the VPC.
resource "aws_vpc" "multi_job_demo" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.name_tag_prefix} VPC"
  }
}

# Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "multi_job_demo" {
  vpc_id = "${aws_vpc.multi_job_demo.id}"

  tags {
    Name = "${var.name_tag_prefix} IGW"
  }
}

# Create a public subnet.
resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.multi_job_demo.id}"
  cidr_block = "${var.subnet_cidr}"
  availability_zone = "${var.subnet_az}"
  map_public_ip_on_launch = true
  #depends_on = ["aws_internet_gateway.multi_job_demo"]

  tags {
    Name = "${var.name_tag_prefix} Public Subnet"
  }
}

# Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.multi_job_demo.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.multi_job_demo.id}"
  }

  tags {
    Name = "${var.name_tag_prefix} Public Route Table"
  }
}

# Now associate the route table with the public subnet
# giving all public subnet instances access to the internet.
resource "aws_route_table_association" "public_subnet" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}
