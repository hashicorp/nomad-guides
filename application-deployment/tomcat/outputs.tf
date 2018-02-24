output "tomcat_server_url" {
    value = "http://${aws_instance.spacelysprockets.0.public_dns}:8080/cart/"
}