resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = "t2.2xlarge"
  key_name               = aws_key_pair.user1.key_name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 40
  }
  user_data = file("./tools-install.sh")

  tags = {
    Name = var.instance-name
  }
}