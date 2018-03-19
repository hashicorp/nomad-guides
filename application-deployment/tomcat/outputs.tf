output "tomcat_server_urls" {
    value = [ "${aws_instance.spacelysprockets.*.public_dns}" ]
}

output "nomad_server_urls" {
    value = [ "${aws_instance.nomadserver.*.public_dns}" ]
}