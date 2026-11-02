# -----------------------------------------------------------------------------
# IAM Module — EC2 Instance Role and Profile
# -----------------------------------------------------------------------------

# EC2 Instance Role
resource "aws_iam_role" "ec2_instance_role" {
  name        = "${var.project_name}-${var.environment}-ec2-instance-role"
  description = "IAM role for EC2 instances — allows SSM, S3 read, CloudWatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# Attach AWS-managed SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom inline policy — S3 read access for app assets bucket
resource "aws_iam_role_policy" "s3_read" {
  name = "${var.project_name}-${var.environment}-s3-read-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAppAssets"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.app_bucket_arn,
          "${var.app_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Custom inline policy — CloudWatch Logs write access
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-cloudwatch-logs-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Custom inline policy — SSM Parameter Store read for secrets
resource "aws_iam_role_policy" "ssm_parameters" {
  name = "${var.project_name}-${var.environment}-ssm-params-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMReadSecrets"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-profile"
  }
}

