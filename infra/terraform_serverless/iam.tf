data "aws_iam_policy_document" "lambda_assume" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "lambda_exec" {
    name               = "${var.project_name}-${var.environment}-lambda-exec"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
    tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ssm_read" {
    name = "${var.project_name}-${var.environment}-ssm-read"
    role = aws_iam_role.lambda_exec.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = ["ssm:GetParameter","ssm:GetParameters","ssm:GetParametersByPath"]
            Resource = "*"
        }]
    })
}

resource "aws_iam_role_policy" "ddb_write" {
  name = "${var.project_name}-${var.environment}-ddb-write"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
       "dynamodb:PutItem",
       "dynamodb:Query"
       ],
      Resource = aws_dynamodb_table.timeline.arn
    }]
  })
}

resource "aws_iam_role_policy" "ecs_access" {
  name = "${var.project_name}-${var.environment}-ecs-access"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ],
      Resource = "*" 
    }]
  })
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-${var.environment}-lambda-s3-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.lambda_deployments.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses_send" {
  name = "${var.project_name}-${var.environment}-ses-send"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ses:SendEmail","ses:SendRawEmail"],
      Resource = "*"
    }]
  })
}