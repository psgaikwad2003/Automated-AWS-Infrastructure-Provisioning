# -----------------------------------------------------------------------------
# ALB Module — External (Web) and Internal (App) Load Balancers
# -----------------------------------------------------------------------------

# ---------- External (Internet-Facing) ALB for Web Tier ----------
resource "aws_lb" "web" {
  name               = "${var.project_name}-${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket != "" ? var.access_logs_bucket : ""
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-alb"
    Tier = "Web"
  }
}

# Web ALB Target Group
resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-tg"
  }
}

# Web ALB HTTP Listener — redirects to HTTPS
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Web ALB HTTPS Listener (uses HTTP for demo; add certificate_arn for production HTTPS)
resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn != "" ? var.certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  lifecycle {
    ignore_changes = [certificate_arn]
  }

  # Only create HTTPS listener if certificate is provided
  count = var.certificate_arn != "" ? 1 : 0
}

# Web ALB HTTP-only Listener (fallback when no certificate)
resource "aws_lb_listener" "web_http_forward" {
  count             = var.certificate_arn != "" ? 0 : 1
  load_balancer_arn = aws_lb.web.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ---------- Internal ALB for App Tier ----------
resource "aws_lb" "app" {
  name               = "${var.project_name}-${var.environment}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.app_alb_sg_id]
  subnets            = var.private_app_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-${var.environment}-app-alb"
    Tier = "Application"
  }
}

# App ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-tg"
  }
}

# App ALB HTTP Listener
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

