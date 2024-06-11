resource "aws_ebs_volume" "additional_volume" {
  availability_zone = var.availability_zone
  size              = var.volume_size
  type              = var.volume_type
  encrypted         = true
  final_snapshot    = var.final_snapshot
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.project_name}_AdditionalVolume_${var.instance_id}"
  }
}


resource "aws_volume_attachment" "additional_volume_attachment" {
  device_name = "/dev/sdf" # Choose an available device name
  instance_id = var.instance_id
  volume_id   = aws_ebs_volume.additional_volume.id
}

