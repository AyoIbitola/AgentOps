variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aws_profile" {
  description = "AWS CLI profile name (SSO-enabled)"
  type        = string
  default     = "agentops"
}

variable "GEMINI_API_KEY" {
  type        = string
  description = "GEMINI API Key"
}

variable "slack_bot_token" {
  type = string
  sensitive = true
}
variable "slack_signing_secret" {
  type = string
  sensitive = true
}
variable "ses_sender"        {
   type = string 
   description = "SES SENDER"
   } 
variable "ses_recipients"    { 
  type = string 
  description = "SES RECIPIENTS"
  } 

variable "jira_base_url"     {
   type = string
   description = "JIRA BASE URL"
    }
variable "jira_email"        { 
  type = string 
  description = "JIRA EMAIL"
  }
variable "jira_api_token"    {
   type = string 
   description = "JIRA API KEY"
   } 
variable "jira_project_key"  { 
  type = string 
  description = "JIRA PROTECT KEY"
  }
variable "jira_issue_type" {
  type    = string
  default = "Task"
}

variable "ecs_cluster_name" {
  type = string
  
}
