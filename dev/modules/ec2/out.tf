output "instance_tags_output" {
  value = var.instance_tags
}

output "private_ip" {
  value = aws_instance.smackdab.private_ip
}

output "id" {
  value = aws_instance.smackdab.id
}
