# -----------------------------------------------------------------------------
# Security Groups Module
# -----------------------------------------------------------------------------

# ---------- Bastion Host SG ----------
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for the bastion host - allows SSH from admin CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

# ---------- External (Web) ALB SG ----------
resource "aws_security_group" "web_alb" {
  name        = "${var.project_name}-${var.environment}-web-alb-sg"
  description = "Security group for the external ALB - allows HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-alb-sg"
  }
}

# ---------- Web Server SG ----------
resource "aws_security_group" "webserver" {
  name        = "${var.project_name}-${var.environment}-webserver-sg"
  description = "Security group for web tier EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from external ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "HTTPS from external ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-webserver-sg"
  }
}

# ---------- Internal (App) ALB SG ----------
resource "aws_security_group" "app_alb" {
  name        = "${var.project_name}-${var.environment}-app-alb-sg"
  description = "Security group for the internal ALB - allows traffic from web servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from web servers"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver.id]
  }

  ingress {
    description     = "HTTP from web servers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-alb-sg"
  }
}

# ---------- App Server SG ----------
resource "aws_security_group" "appserver" {
  name        = "${var.project_name}-${var.environment}-appserver-sg"
  description = "Security group for application tier EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-appserver-sg"
  }
}

# ---------- Database SG ----------
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Security group for RDS database - allows traffic from app servers only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  ingress {
    description     = "PostgreSQL from app servers (if using postgres)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-database-sg"
  }
}

