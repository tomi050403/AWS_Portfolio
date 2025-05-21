# ---
# Key Pair
# ---
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("../../src/flask-app-project.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

# ---
# EC2 instance
# ---
# app sv
resource "aws_instance" "appsv" {
  ami                         = var.app_sv_ami
  instance_type               = var.appsv_instance_type
  subnet_id                   = var.private_subnet_1a
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.app_sg_id]
  iam_instance_profile        = var.ec2_profile_name

  key_name = aws_key_pair.keypair.key_name

  tags = {
    Name    = "${var.project}-${var.environment}-appsv"
    Project = var.project
    Env     = var.environment
    type    = "appsv"
  }
}

# web sv
resource "aws_instance" "websv" {
  ami                         = var.web_sv_ami
  instance_type               = var.websv_instance_type
  subnet_id                   = var.public_subnet_1a
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.web_sg_id]
  iam_instance_profile        = var.ec2_profile_name

  key_name = aws_key_pair.keypair.key_name

  tags = {
    Name    = "${var.project}-${var.environment}-websv"
    Project = var.project
    Env     = var.environment
    type    = "websv"
  }
}

########################################################
# Outputs
########################################################
output "appsv_instance_private_ip" {
  value = aws_instance.appsv.private_ip
}

output "web_server_id" {
  value = aws_instance.websv.id
}