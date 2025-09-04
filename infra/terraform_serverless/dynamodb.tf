resource "aws_dynamodb_table" "timeline"{
    name = "${var.project_name}-${var.environment}-timeline"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "incident_id"
    range_key = "ts"

    attribute {
      name = "incident_id"
      type = "S"
    }

    attribute {
      name = "ts"
      type = "N"
    }

    tags = var.tags
}