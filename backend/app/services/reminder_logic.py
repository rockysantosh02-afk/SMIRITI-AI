"""Reminder due-date and escalation business logic."""

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

from firebase_admin import firestore

from app.core.firebase_admin import get_firestore
from app.core.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)


def _as_datetime(value: Any) -> Optional[datetime]:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            return None
    return None


def should_escalate(reminder: Dict[str, Any], now: Optional[datetime] = None) -> bool:
    """Return whether an active, unacknowledged reminder is due."""
    if reminder.get("status", "active") != "active":
        return False
    scheduled = _as_datetime(reminder.get("scheduled_time"))
    current = now or datetime.now(timezone.utc)
    return scheduled is not None and scheduled <= current


def check_due_reminders() -> List[Dict[str, Any]]:
    """Find active reminders whose scheduled time has passed and escalate them."""
    now = datetime.now(timezone.utc)
    due: List[Dict[str, Any]] = []
    for snapshot in get_firestore().collection("reminders").where("status", "==", "active").stream():
        reminder = {"id": snapshot.id, **(snapshot.to_dict() or {})}
        if should_escalate(reminder, now):
            due.append(reminder)
            process_escalation(snapshot.id)
    return due


def process_escalation(reminder_id: str) -> None:
    """Mark a missed reminder, create an alert, and broadcast it to caregivers."""
    client = get_firestore()
    reference = client.collection("reminders").document(reminder_id)
    snapshot = reference.get()
    if not snapshot.exists:
        raise ValueError(f"Reminder not found: {reminder_id}")
    reminder = snapshot.to_dict() or {}
    if reminder.get("status") == "acknowledged":
        return
    reference.update({"status": "escalated", "escalated_at": firestore.SERVER_TIMESTAMP})
    alert_id = create_alert(
        str(reminder.get("patient_id", "")),
        f"Missed reminder: {reminder.get('label', 'scheduled task')}",
        "high",
    )
    import asyncio

    message = {"type": "reminder_escalated", "reminder_id": reminder_id, "alert_id": alert_id}
    try:
        asyncio.get_running_loop().create_task(websocket_manager.broadcast(str(reminder.get("patient_id", "")), message))
    except RuntimeError:
        logger.info("No active event loop for reminder broadcast %s", reminder_id)


def create_alert(patient_id: str, message: str, severity: str) -> str:
    """Create a patient alert and return its generated ID."""
    reference = get_firestore().collection("alerts").document(uuid4().hex)
    reference.set({"patient_id": patient_id, "message": message, "severity": severity, "created_at": firestore.SERVER_TIMESTAMP})
    return reference.id
