# ---
# SG
# ---
# ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "alb role SG"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.environment}-alb-sg"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_security_group_rule" "alb_sg_in_http" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["${var.ALB_from_IP}"]
}
resource "aws_security_group_rule" "alb_sg_out_default" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["10.10.0.0/16"]
}

# websv
resource "aws_security_group" "websv_sg" {
  name        = "${var.project}-${var.environment}-websv-sg"
  description = "web server role SG"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.environment}-websv-sg"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_security_group_rule" "websv_sg_in_http" {
  security_group_id        = aws_security_group.websv_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "websv_sg_out_default" {
  security_group_id = aws_security_group.websv_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}


# appsv
resource "aws_security_group" "appsv_sg" {
  name        = "${var.project}-${var.environment}-appsv-sg"
  description = "app server role SG"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.environment}-appsv-sg"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_security_group_rule" "appsv_sg_in_app8000" {
  security_group_id = aws_security_group.appsv_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8000
  to_port           = 8000
  source_security_group_id = aws_security_group.websv_sg.id
}
resource "aws_security_group_rule" "appsv_sg_out_default" {
  security_group_id = aws_security_group.appsv_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}


#RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "rds role SG"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.environment}-rds-sg"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_security_group_rule" "rds_sg_in_mysql" {
  security_group_id        = aws_security_group.rds_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.appsv_sg.id
}


########################################################
# Outputs
########################################################
output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "web_sg_id" {
  value = aws_security_group.websv_sg.id
}

output "app_sg_id" {
  value = aws_security_group.appsv_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
