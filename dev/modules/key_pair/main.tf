resource "aws_key_pair" "smackdab_dev_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}
