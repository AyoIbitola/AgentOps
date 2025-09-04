import asyncio
import json
from mangum import Mangum
from app.main import (
    app,
    process_incident,
    new_incident_id,
    record_timeline,
    normalize_eventbridge_event,
)

asgi_handler = Mangum(app)


def is_http_event(event):
    rc = event.get("requestContext") if isinstance(event, dict) else None
    return bool(rc and rc.get("http"))


async def handle_eventbridge_event_async(event, context):
    detail = normalize_eventbridge_event(event)
    incident_id = event.get("incident_id") or new_incident_id()

    record_timeline(incident_id, "received_eventbridge", {"detail": detail})
    ai_result = await process_incident(detail, incident_id, source="eventbridge")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "status": "incident handled(eventbridge)",
            "incident_id": incident_id,
            "ai": ai_result
        }),
        "headers": {"content-type": "application/json"},
    }


def handle_eventbridge_event(event, context):
    return asyncio.run(handle_eventbridge_event_async(event, context))


def entrypoint(event, context):
    
    if isinstance(event, dict) and is_http_event(event):
        
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        return asgi_handler(event, context)
    else:
        return handle_eventbridge_event(event, context)
