# ---
# ALB
# ---
resource "aws_lb" "alb" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    var.alb_sg_id
  ]
  subnets = [
    var.public_subnet_1a,
    var.public_subnet_1c
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-alb"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_listener" "aws_listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }

  tags = {
    Name    = "${var.project}-${var.environment}-listener_http"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "${var.project}-${var.environment}-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.environment}-targetgroup"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_target_group_attachment" "aws_lb_target_group_attach" {
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id = var.web_server_id
}