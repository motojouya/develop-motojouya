resource "aws_instance" "develop" {
  ami           = var.ami_id
  instance_type = var.instance_type

  associate_public_ip_address = true
  availability_zone           = var.availability_zone
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = ["${var.security_group_id}"]

  key_name             = var.keypair_name
  iam_instance_profile = var.profile_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.max_price
    }
  }

  user_data = <<EOF
#!/bin/bash
curl https://raw.githubusercontent.com/motojouya/develop-motojouya/main/resources/init.sh | bash -s -- ${var.region} ${var.ssh_port} ${var.volume_id} ${var.device_name} ${var.user_name} ${var.domain} ${var.hosted_zone_id}
EOF

  tags = {
    Name = "develop"
  }
}

resource "aws_volume_attachment" "develop_ebs_attachment" {
  device_name = var.device_name
  volume_id   = "vol-${var.volume_id}"
  instance_id = aws_instance.develop.id
}
