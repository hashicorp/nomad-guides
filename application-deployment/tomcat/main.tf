provider "aws" {                                             
  region     = "${var.region}"                                    
}

# Template for database backup
data "template_file" "spacely_backup" {
    template = "${file("./files/spacely_backup.sql.tpl")}"

    vars {
        store_name = "${var.store_name}"
    }
}

resource "aws_instance" "nomadserver" {
    ami = "${var.demoami}"
    instance_type = "${var.nomad_instance_type}"
    key_name = "${var.key_name}"
    count = "1"
    vpc_security_group_ids = ["${aws_security_group.demo_ecommerce.id}"]
    # This puts one server in each subnet, up to the total number of subnets.
    subnet_id = "${lookup(var.subnets, count.index % var.nomad_servers)}"

    # This is the provisioning user
    connection {
        user = "${var.user}"
        private_key = "${file("${var.private_key_file}")}"
    }

    # AWS Instance Tags
    tags {
        Name = "nomad-server-${count.index}"
        owner = "${var.key_name}"
        TTL = "24"
    }

    # Set SELinux to non-enforcing mode
    provisioner "remote-exec" {
        inline = [
            "sudo setenforce 0"
        ]
    }



}

# Let's deploy our legacy Tomcat application using Terraform
resource "aws_instance" "spacelysprockets" {
    ami = "${var.demoami}"
    instance_type = "${var.ecommerce_instance_type}"
    key_name = "${var.key_name}"
    count = "${var.ecommerce_servers}"
    vpc_security_group_ids = ["${aws_security_group.demo_ecommerce.id}"]
    # This puts one server in each subnet, up to the total number of subnets.
    subnet_id = "${lookup(var.subnets, count.index % var.ecommerce_servers)}"

    # This is the provisioning user
    connection {
        user = "${var.user}"
        private_key = "${file("${var.private_key_file}")}"
    }

    # AWS Instance Tags
    tags {
        Name = "${var.ecomTagName}-dev-${count.index}"
        owner = "${var.key_name}"
        TTL = "24"
    }

    # Set SELinux to non-enforcing mode
    provisioner "remote-exec" {
        inline = [
            "sudo setenforce 0"
        ]
    }

    # Render the mysql backup template
    provisioner "file" {
        content = "${data.template_file.spacely_backup.rendered}"
        destination = "/home/ec2-user/spacely_backup.sql"
    }

    # Execute bash script to install mariadb, tomcat, shopping cart, and restore database
    provisioner "remote-exec" {
        scripts = [
            "${path.module}/files/install_shopping_cart.sh"
        ]
    }

    # Required for shopping cart back end encryption
    # TODO: Vault demo integration?
    provisioner "file" {
        source = "files/twoWay.key"
        destination = "/home/ec2-user/twoWay.key"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo cp /home/ec2-user/twoWay.key /usr/share/tomcat/webapps/cart/WEB-INF/conf/keys/twoWay.key"
        ]
    }

    # Application settings properties files
    provisioner "file" {
        source = "files/appSettings.properties"
        destination = "/home/ec2-user/appSettings.properties"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo cp /home/ec2-user/appSettings.properties /usr/share/tomcat/webapps/cart/WEB-INF/classes/appSettings.properties"
        ]
    }

    provisioner "file" {
        source = "files/hibernate.properties"
        destination = "/home/ec2-user/hibernate.properties"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo cp /home/ec2-user/hibernate.properties /usr/share/tomcat/webapps/cart/WEB-INF/classes/hibernate.properties"
        ]
    }

    # Restart tomcat to activate settings
    provisioner "remote-exec" {
        inline = [
            "sudo systemctl restart tomcat"
        ]
    }

}

resource "aws_security_group" "demo_ecommerce" {
    name = "demo_ecommerce"
    description = "Ecommerce website security group"
    vpc_id = "${var.vpc_id}"
    # AWS Instance Tags
    tags {
        Name = "dev-sg"
    }

    // These are for internal traffic
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        self = true
    }

    // HTTP traffic
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // Tomcat traffic
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // HTTPS traffic
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // For remote access via SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // This is for outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}