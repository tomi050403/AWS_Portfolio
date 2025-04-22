# ---
# Private Host Zone
# ---
resource "aws_route53_zone" "network-private_host_zone" {
  name          = var.private_host_zone
  comment       = "private host zone"
  force_destroy = true

  vpc {
    vpc_id     = var.vpc_id
    vpc_region = var.region
  }

  tags = {
    Name    = "${var.project}-${var.environment}-private-host-zone"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route53_record" "network-private_zone_record" {
  zone_id = aws_route53_zone.network-private_host_zone.id
  name    = "app.${var.environment}"
  type    = "A"
  ttl     = 300
  records = [var.appsv_instance_private_ip]
}

