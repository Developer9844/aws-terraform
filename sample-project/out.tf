output "private_key" {
  value     = module.ssh_key.private_key
  sensitive = true
}
output "public_key" {
  value     = module.ssh_key.public_key
  sensitive = true
}


output "subnet_id" {
  value = module.vpc_demo.subnet_id
}

output "sg_id" {
  value = module.vpc_demo.sg_id
}

