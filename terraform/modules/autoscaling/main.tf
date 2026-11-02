# -----------------------------------------------------------------------------
# Auto Scaling Module — Web and App Tier ASGs with Scaling Policies
# -----------------------------------------------------------------------------

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# =============================================================================
# WEB TIER
# =============================================================================

# Web Tier Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.web_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.webserver_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # Update and install nginx
    dnf update -y
    dnf install -y nginx amazon-cloudwatch-agent

    # Create health check endpoint
    mkdir -p /usr/share/nginx/html
    echo '{"status":"ok","tier":"web"}' > /usr/share/nginx/html/health

    # Configure nginx
    cat > /etc/nginx/nginx.conf <<'NGINXCONF'
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /run/nginx.pid;

    events {
        worker_connections 1024;
        use epoll;
        multi_accept on;
    }

    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;
        sendfile      on;
        tcp_nopush    on;
        tcp_nodelay   on;
        keepalive_timeout 65;
        gzip          on;
        gzip_vary     on;
        gzip_types    text/plain text/css application/json application/javascript;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Hide nginx version
        server_tokens off;

        log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent"';
        access_log /var/log/nginx/access.log main;

        upstream app_backend {
            server ${var.app_alb_dns_name}:8080;
            keepalive 32;
        }

        server {
            listen 80 default_server;
            root /usr/share/nginx/html;
            index index.html;

            location /health {
                access_log off;
                return 200 '{"status":"ok","tier":"web"}';
                add_header Content-Type application/json;
            }

            location /api/ {
                proxy_pass http://app_backend/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_connect_timeout 30s;
                proxy_read_timeout 60s;
            }

            location / {
                try_files $uri $uri/ /index.html;
            }
        }
    }
    NGINXCONF

    # Create a simple index.html
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head><meta charset="UTF-8"><title>AWS 3-Tier App</title></head>
    <body>
    <h1>Web Tier — Running on AWS</h1>
    <p>Served by nginx on Amazon Linux 2023</p>
    </body>
    </html>
    HTML

    # Enable and start nginx
    systemctl enable nginx
    systemctl start nginx

    # CloudWatch agent config
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "metrics": {
        "namespace": "${var.project_name}/${var.environment}/WebTier",
        "metrics_collected": {
          "cpu": {"measurement": ["cpu_usage_active"], "metrics_collection_interval": 60},
          "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60}
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {"file_path": "/var/log/nginx/access.log", "log_group_name": "/ec2/web/nginx-access"},
              {"file_path": "/var/log/nginx/error.log", "log_group_name": "/ec2/web/nginx-error"}
            ]
          }
        }
      }
    }
    CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-web-server"
      Role        = "webserver"
      Environment = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-web-volume"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Web Tier Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-${var.environment}-web-asg"
  min_size                  = var.web_asg_min
  max_size                  = var.web_asg_max
  desired_capacity          = var.web_asg_desired
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.web_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_cooldown          = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Web ASG Scale-Up Policy
resource "aws_autoscaling_policy" "web_scale_up" {
  name                   = "${var.project_name}-${var.environment}-web-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# Web ASG Scale-Down Policy
resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "${var.project_name}-${var.environment}-web-scale-down"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm — Web CPU High
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up web ASG when CPU >= 70%"
  alarm_actions       = [aws_autoscaling_policy.web_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# CloudWatch Alarm — Web CPU Low
resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down web ASG when CPU <= 20%"
  alarm_actions       = [aws_autoscaling_policy.web_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# =============================================================================
# APP TIER
# =============================================================================

# App Tier Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-app-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.app_instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.appserver_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # Update system
    dnf update -y
    dnf install -y amazon-cloudwatch-agent curl wget git jq

    # Install Node.js 20 (LTS)
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs

    # Create app user
    useradd -r -s /sbin/nologin appuser || true

    # Create app directory
    mkdir -p /opt/app
    chown appuser:appuser /opt/app

    # Create a simple Express.js health check app
    cat > /opt/app/app.js <<'APPJS'
    const http = require('http');

    const PORT = process.env.PORT || 8080;

    const server = http.createServer((req, res) => {
      if (req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({status: 'ok', tier: 'app', timestamp: new Date().toISOString()}));
        return;
      }
      res.writeHead(200, {'Content-Type': 'application/json'});
      res.end(JSON.stringify({message: 'App tier running', path: req.url}));
    });

    server.listen(PORT, '0.0.0.0', () => {
      console.log('App server listening on port ' + PORT);
    });
    APPJS

    chown appuser:appuser /opt/app/app.js

    # Create systemd service
    cat > /etc/systemd/system/appserver.service <<'SVCEOF'
    [Unit]
    Description=Application Server
    After=network.target
    Requires=network.target

    [Service]
    Type=simple
    User=appuser
    WorkingDirectory=/opt/app
    ExecStart=/usr/bin/node /opt/app/app.js
    Restart=always
    RestartSec=10
    StandardOutput=journal
    StandardError=journal
    SyslogIdentifier=appserver
    Environment=NODE_ENV=production
    Environment=PORT=8080

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable appserver
    systemctl start appserver

    # CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "metrics": {
        "namespace": "${var.project_name}/${var.environment}/AppTier",
        "metrics_collected": {
          "cpu": {"measurement": ["cpu_usage_active"], "metrics_collection_interval": 60},
          "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60}
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {"file_path": "/var/log/messages", "log_group_name": "/ec2/app/messages"}
            ]
          }
        }
      }
    }
    CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-server"
      Role        = "appserver"
      Environment = var.environment
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-volume"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# App Tier Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-${var.environment}-app-asg"
  min_size                  = var.app_asg_min
  max_size                  = var.app_asg_max
  desired_capacity          = var.app_asg_desired
  vpc_zone_identifier       = var.private_app_subnet_ids
  target_group_arns         = [var.app_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_cooldown          = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# App ASG Scale-Up Policy
resource "aws_autoscaling_policy" "app_scale_up" {
  name                   = "${var.project_name}-${var.environment}-app-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# App ASG Scale-Down Policy
resource "aws_autoscaling_policy" "app_scale_down" {
  name                   = "${var.project_name}-${var.environment}-app-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm — App CPU High
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-app-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up app ASG when CPU >= 70%"
  alarm_actions       = [aws_autoscaling_policy.app_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# CloudWatch Alarm — App CPU Low
resource "aws_cloudwatch_metric_alarm" "app_cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-app-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down app ASG when CPU <= 20%"
  alarm_actions       = [aws_autoscaling_policy.app_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

