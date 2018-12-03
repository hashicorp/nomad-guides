# Outputs

output "vpc_id" {
  value = "${aws_vpc.multi_job_demo.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}
