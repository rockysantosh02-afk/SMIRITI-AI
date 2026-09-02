"""Dependency-free outbox queue for offline writes."""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4


class OutboxManager:
    """Persist pending writes in memory and expose deterministic sync operations."""

    def __init__(self) -> None:
        self._entries: Dict[str, Dict[str, Any]] = {}

    def enqueue(self, collection: str, data: Dict[str, Any], entry_id: Optional[str] = None) -> str:
        """Add an idempotent pending write and return its entry ID."""
        key = entry_id or uuid4().hex
        self._entries.setdefault(key, {"id": key, "collection": collection, "data": dict(data), "status": "pending", "created_at": datetime.now(timezone.utc)})
        return key

    def pending(self) -> List[Dict[str, Any]]:
        """Return pending entries in insertion order."""
        return [entry for entry in self._entries.values() if entry["status"] == "pending"]

    def mark_completed(self, entry_id: str) -> None:
        """Mark an existing entry as synced."""
        if entry_id in self._entries:
            self._entries[entry_id]["status"] = "completed"

    def all_entries(self) -> List[Dict[str, Any]]:
        """Return all queued entries."""
        return list(self._entries.values())