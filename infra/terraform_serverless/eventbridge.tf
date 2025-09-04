
resource "aws_cloudwatch_event_rule" "incident" {
  name        = "${var.project_name}-${var.environment}-incident"
  description = "AgentOps incident events"

 
  # event_pattern = jsonencode({
  #   "source": ["aws.ecs"],
  #   "detail-type": ["ECS Task State Change"]
  # })

 
  event_pattern = jsonencode({
    "source": ["agentops"],
    "detail-type": ["incident.alert"]
  })

  tags = var.tags
}


resource "aws_cloudwatch_event_target" "incident_to_lambda" {
  rule      = aws_cloudwatch_event_rule.incident.name
  target_id = "lambda"
  arn       = aws_lambda_function.agent.arn
}


resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.incident.arn
}
