# AI Incident Response Agent 

An intelligent, autonomous incident response system that uses AI to analyze alerts, make decisions, and take appropriate actions automatically. Built with FastAPI, AWS services, and Google's Gemini AI.

## 🏗️ Architecture

The system follows a serverless architecture pattern:

![Architecture Diagram](assets/images/architecture-diagram.png)


## ✨ Features

- ** AI-Powered Decision Making**: Uses Google Gemini AI to analyze incidents and determine appropriate responses
- ** Timeline Tracking**: Complete audit trail of all incident events stored in DynamoDB
- ** Automated Actions**: Can automatically restart ECS services, notify teams, or escalate issues
- ** Multi-Channel Notifications**: Integrates with Slack, email (SES), and Jira
- ** Secure Slack Integration**: Proper signature verification for Slack webhook security
- ** Serverless**: Runs on AWS Lambda with API Gateway for scalability

## 🛠️ Technology Stack

- **Backend**: FastAPI (Python)
- **AI/ML**: Google Gemini AI (gemini-1.5-flash)
- **Cloud Provider**: AWS
  - Lambda (Serverless compute)
  - API Gateway (HTTP endpoints)
  - DynamoDB (Timeline storage)
  - ECS (Container orchestration)
  - SES (Email notifications)
  - EventBridge (Event routing)
- **Integrations**: 
  - Slack (Team notifications)
  - Jira (Ticket management)
- **Infrastructure**: Terraform

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- AWS CLI configured
- Terraform installed
- Google Cloud API key (Gemini)
- Slack Bot Token (optional)
- Jira API credentials (optional)

### Environment Variables

Set up the following environment variables:

```bash
# Required
GEMINI_API_KEY=your_gemini_api_key
TIMELINE_TABLE=incident-timeline-table
ECS_CLUSTER_NAME=your-ecs-cluster

# Optional integrations
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_SIGNING_SECRET=your-slack-signing-secret
JIRA_URL=https://your-domain.atlassian.net
JIRA_USER=your-jira-email
JIRA_TOKEN=your-jira-api-token
SES_SENDER=notifications@yourdomain.com
EMAIL_RECIPIENT=team@yourdomain.com
AWS_REGION=us-east-2
```

### Deployment

1. **Build and deploy the Lambda function:**
   ```bash
   cd app
   rm -rf build function.zip
   mkdir build
   pip install -r requirements.txt -t build/ --platform manylinux2014_x86_64 --only-binary=:all: --upgrade
   cp -r app build/app
   cp app/handler.py build/handler.py
   python -c "
   import zipfile, os
   zf = zipfile.ZipFile('function.zip', 'w', zipfile.ZIP_DEFLATED)
   for root, _, files in os.walk('build'):
       for f in files:
           file_path = os.path.join(root, f)
           arc_path = os.path.relpath(file_path, 'build')
           zf.write(file_path, arc_path)
   zf.close()
   "
   ```

2. **Deploy infrastructure:**
   ```bash
   cd ../infra/terraform_serverless
   terraform apply -auto-approve
   ```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --port 8000
```

## 📡 API Endpoints

### Health Check
```http
GET /
GET /health
```

### Alert Processing
```http
POST /alert
Content-Type: application/json

{
  "incident_id": "optional-custom-id",
  "detail": {
    "service_name": "my-service",
    "cluster_name": "production",
    "summary": "High error rate detected",
    "Trigger": {
      "Dimensions": [
        {"name": "ServiceName", "value": "web-service"},
        {"name": "ClusterName", "value": "prod-cluster"}
      ]
    }
  }
}
```

### Slack Actions
```http
POST /slack/actions
# Handles interactive Slack button clicks
# Automatically verified with Slack signature
```

## 🤖 AI Decision Logic

The AI agent analyzes incidents and returns structured decisions:

```json
{
  "decision": "SAFE" | "ESCALATE",
  "action": "restart_service" | "notify_team" | "ignore",
  "message": "Human-readable summary (≤200 chars)"
}
```

**Decision Types:**
- `SAFE`: Routine issue, automated action appropriate
- `ESCALATE`: Requires human intervention

**Available Actions:**
- `restart_service`: Automatically restart the affected ECS service
- `notify_team`: Send notifications via all configured channels
- `ignore`: No action needed (logged for audit)

## 📊 Timeline Tracking

Every incident maintains a complete timeline in DynamoDB:

- Event reception
- AI analysis results
- Actions taken
- Slack interactions
- Service restarts
- Notifications sent

Access via Slack: Click "📜 View Timeline" button on incident notifications.

## 🔧 Configuration

### Slack Integration

1. Create a Slack app with Bot Token scopes:
   - `chat:write`
   - `chat:write.public`

2. Set up Interactive Components endpoint:
   - `https://your-api-gateway-url/slack/actions`

3. Add environment variables:
   ```bash
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_SIGNING_SECRET=your-signing-secret
   ```

### Jira Integration

1. Generate API token in Jira
2. Configure project key in the code (default: "SCRUM")
3. Set environment variables:
   ```bash
   JIRA_URL=https://your-domain.atlassian.net
   JIRA_USER=your-email@company.com
   JIRA_TOKEN=your-api-token
   ```

### AWS SES Email

1. Verify sender email in SES console
2. Set environment variables:
   ```bash
   SES_SENDER=notifications@yourdomain.com
   EMAIL_RECIPIENT=team@yourdomain.com
   ```

## 🔍 Monitoring and Debugging

### Logs
All actions are logged with structured JSON for easy parsing:
```
[timeline] wrote: {"incident_id": "...", "ts": 1234567890, "action": "ai_assessment", "data": {...}}
```

### Error Handling
- AI failures fall back to "ESCALATE" decision
- Service restart failures are logged and reported
- Network timeouts include retry logic with exponential backoff

### Health Checks
- `GET /health` - Simple health check
- `GET /` - Application status with emoji indicators

## 🛡️ Security

- **Slack Webhook Verification**: HMAC-SHA256 signature validation
- **Request Timestamp Validation**: Prevents replay attacks (5-minute window)
- **Environment Variable Security**: Sensitive credentials stored as environment variables
- **AWS IAM**: Least-privilege access for Lambda execution role

## 📈 Scaling Considerations

- **Lambda Concurrency**: Configure reserved concurrency for predictable performance
- **DynamoDB**: Uses on-demand billing, scales automatically
- **API Gateway**: Built-in throttling and caching capabilities
- **Error Handling**: Circuit breaker pattern for external service calls

## 🧪 Testing

### Unit Tests
```bash
pytest tests/
```

### Integration Testing
```bash
# Test alert endpoint
curl -X POST https://your-api-gateway-url/alert \
  -H "Content-Type: application/json" \
  -d '{"detail": {"service_name": "test-service", "summary": "Test incident"}}'
```

## 📋 TODO / Roadmap

- [ ] Add support for multiple notification channels per incident
- [ ] Implement incident severity levels
- [ ] Add dashboard for incident analytics
- [ ] Support for custom AI prompts per service
- [ ] Integration with PagerDuty
- [ ] Webhook support for external systems
- [ ] Enhanced security with API keys

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request



## 🆘 Support

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Documentation**: Check the `/docs` folder for detailed guides
- **Community**: Join our Slack workspace for discussions

---

**Built with ❤️ for reliable incident response automation**