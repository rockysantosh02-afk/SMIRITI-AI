"""Reminder due-date and self-directed follow-up business logic."""

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from firebase_admin import firestore

from app.core.firebase_admin import get_firestore

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


def check_due_reminders(user_id: str | None = None) -> List[Dict[str, Any]]:
    """Find due reminders, optionally limited to one authenticated user."""
    now = datetime.now(timezone.utc)
    due: List[Dict[str, Any]] = []
    query = get_firestore().collection("reminders").where("status", "==", "active")
    if user_id is not None:
        query = query.where("user_id", "==", user_id)
    for snapshot in query.stream():
        reminder = {"id": snapshot.id, **(snapshot.to_dict() or {})}
        if should_escalate(reminder, now):
            result = process_missed_reminder(reminder)
            due.append({**reminder, "status": "missed", **result})
    return due


def process_missed_reminder(reminder: Dict[str, Any]) -> Dict[str, str]:
    """Mark a reminder missed and return a kind, self-directed follow-up."""
    client = get_firestore()
    message = "It's okay to miss a reminder sometimes. Want to try again?"
    if str(reminder.get("language", reminder.get("preferred_language", "en"))).startswith("hi"):
        message = "कभी-कभी रिमाइंडर छूट जाना ठीक है। क्या आप फिर से कोशिश करना चाहेंगे?"
    reminder_id = str(reminder.get("id", reminder.get("reminder_id", "")))
    if reminder_id:
        client.collection("reminders").document(reminder_id).update(
            {"status": "missed", "follow_up_message": message, "updated_at": firestore.SERVER_TIMESTAMP}
        )
    return {"follow_up_message": message}
