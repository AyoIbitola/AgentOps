from fastapi import FastAPI, Request , Header , HTTPException
from typing import Any, Dict
import os, json, time, uuid, asyncio , hmac , hashlib
import httpx
import boto3

import google.generativeai as genai
import aioboto3
from decimal import Decimal
from app.automations import new_incident_id, normalize_eventbridge_event, process_incident, restart_service, record_timeline, get_timeline, format_timeline_for_slack, send_slack
ECS_CLUSTER_NAME = os.getenv("ECS_CLUSTER_NAME")
SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET", "") 
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

app = FastAPI()


@app.get("/")
def root():
    return {"message": "AI agent is live 🚀🤖"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/alert")
async def alert(request: Request):
    payload = await request.json()
    incident_id = payload.get("incident_id") or new_incident_id()
    detail = normalize_eventbridge_event(payload)
    ai_result = await process_incident(detail, incident_id, source="eventbridge")
    return {"status": "incident handled", "incident_id": incident_id, "ai": ai_result}

@app.post("/slack/actions")
async def slack_actions(
    request: Request,
    x_slack_signature: str = Header(None),
    x_slack_request_timestamp: str = Header(None)
):
    
    if not SLACK_SIGNING_SECRET:
        raise HTTPException(status_code=500, detail="Slack signing secret not configured")

    raw_body = await request.body()
    timestamp = x_slack_request_timestamp
    sig_basestring = f"v0:{timestamp}:{raw_body.decode()}"
    my_sig = "v0=" + hmac.new(SLACK_SIGNING_SECRET.encode(), sig_basestring.encode(), hashlib.sha256).hexdigest()

    
    if not hmac.compare_digest(my_sig, x_slack_signature):
        raise HTTPException(status_code=403, detail="Invalid Slack signature")

    
    if abs(time.time() - int(timestamp)) > 60 * 5:
        raise HTTPException(status_code=403, detail="Request too old")

   
    form = await request.form()
    payload = json.loads(form["payload"])
    user = payload["user"]["username"]
    action = payload["actions"][0]
    value = json.loads(action["value"])
    incident_id, action_name = value["incident_id"], value["action"]

    
    if action_name == "restart_service":
        service_name = value.get("service_name", "my-service")
        cluster_name = value.get("cluster_name", ECS_CLUSTER_NAME)
        result = await restart_service(service_name, cluster_name)
        record_timeline(incident_id, "slack_restart", {"by": user, "result": result})
        await send_slack(f"🔄 {user} restarted service `{service_name}` in `{cluster_name}` for incident {incident_id}", incident_id, channel=payload["channel"]["id"])

    elif action_name == "view_timeline":
        items = get_timeline(incident_id)
        msg = format_timeline_for_slack(incident_id, items)
        await send_slack(msg, incident_id, channel=payload["channel"]["id"])

    elif action_name == "ack":
        record_timeline(incident_id, "slack_ack", {"by": user})
        await send_slack(f"✅ {user} acknowledged incident {incident_id}", incident_id, channel=payload["channel"]["id"])

    return {"ok": True}