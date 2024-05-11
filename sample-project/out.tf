output "private_key" {
  value     = module.ssh_key.private_key
  sensitive = true
}
output "public_key" {
  value     = module.ssh_key.public_key
  sensitive = true
}



