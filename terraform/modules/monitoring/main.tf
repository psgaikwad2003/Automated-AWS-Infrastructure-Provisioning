# -----------------------------------------------------------------------------
# CloudWatch Monitoring Module — Dashboards & Metric Alarms
# -----------------------------------------------------------------------------

# SNS Topic for Infrastructure Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-infra-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-infra-alerts"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms
# -----------------------------------------------------------------------------

# 1. External ALB 5xx High Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggered when External ALB receives more than 10 5XX errors in 2 consecutive minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.web_alb_arn_suffix
  }
}

# 2. RDS Low Free Storage Space Alarm (< 5 GB)
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5 GB in bytes
  alarm_description   = "Triggered when RDS free storage space falls below 5 GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# 3. RDS High CPU Alarm (> 85%)
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggered when RDS CPU utilization exceeds 85% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Operational Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "External ALB: Request Count & 5XX Errors"
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.web_alb_arn_suffix, { color = "#2ca02c" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { color = "#d62728", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time (Latency)"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.web_alb_arn_suffix, { label = "Web ALB Latency" }],
            [".", ".", "LoadBalancer", var.app_alb_arn_suffix, { label = "App ALB Latency" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Auto Scaling Groups: CPU Utilization"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_name, { label = "Web ASG CPU %" }],
            [".", ".", "AutoScalingGroupName", var.app_asg_name, { label = "App ASG CPU %" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS: CPU Utilization & Free Storage"
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { label = "RDS CPU %" }],
            [".", "FreeStorageSpace", ".", ".", { label = "Free Storage (bytes)", yAxis = "right" }]
          ]
        }
      }
    ]
  })
}
