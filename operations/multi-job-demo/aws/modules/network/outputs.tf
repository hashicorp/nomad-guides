# Outputs

output "vpc_id" {
  value = "${aws_vpc.multi_job_demo.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}

output "route_table_association_id" {
  value = "${aws_route_table_association.public_subnet.id}"
}
