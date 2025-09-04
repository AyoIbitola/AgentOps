locals {
  zip_path = "${path.module}/../../app/function.zip"
}


resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "${var.project_name}-${var.environment}-lambda-deployments"
  tags   = var.tags
}


resource "aws_s3_bucket_public_access_block" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_deployments.bucket
  key    = "agent-function-${filebase64sha256(local.zip_path)}.zip"
  source = local.zip_path
  etag   = filemd5(local.zip_path)
  tags   = var.tags
}


resource "aws_lambda_function" "agent" {
  function_name = "${var.project_name}-${var.environment}-agent"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "app.handler.entrypoint"      
  runtime       = "python3.11"
  
  
  s3_bucket         = aws_s3_object.lambda_zip.bucket
  s3_key            = aws_s3_object.lambda_zip.key
  source_code_hash  = filebase64sha256(local.zip_path)
  
  timeout     = 20
  memory_size = 256
  
  environment {
    variables = {
      GEMINI_API_KEY = var.GEMINI_API_KEY
      ENV            = var.environment
      TIMELINE_TABLE = aws_dynamodb_table.timeline.name  
      ECS_CLUSTER_NAME     = var.ecs_cluster_name
      SLACK_BOT_TOKEN      = var.slack_bot_token
      SLACK_SIGNING_SECRET = var.slack_signing_secret
      JIRA_URL             = var.jira_base_url
      JIRA_USER            = var.jira_email
      JIRA_TOKEN           = var.jira_api_token
      SES_SENDER           = var.ses_sender
      EMAIL_RECIPIENT      = var.ses_recipients
    }
  }
  
  
  timeouts {
    create = "15m"
    update = "15m"
  }
  
  tags = var.tags
  
  
  depends_on = [aws_s3_object.lambda_zip]
}