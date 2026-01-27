resource "aws_key_pair" "user1" {
  key_name   = "user1"
  public_key = file("${path.module}/user1.pub")
}