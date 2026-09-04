"""Offline outbox synchronization and deterministic conflict resolution."""

from typing import Any, Callable, Dict, List

from app.core.outbox_manager import OutboxManager


class SyncService:
    """Flush outbox entries through a supplied remote writer."""

    def __init__(self, outbox: OutboxManager | None = None) -> None:
        self.outbox = outbox or OutboxManager()

    def sync(self, writer: Callable[[str, Dict[str, Any]], None]) -> List[str]:
        """Write pending entries and mark them completed after success."""
        completed: List[str] = []
        for entry in self.outbox.pending():
            writer(entry["collection"], entry["data"])
            self.outbox.mark_completed(entry["id"])
            completed.append(entry["id"])
        return completed

    @staticmethod
    def resolve_last_write_wins(local: Dict[str, Any], remote: Dict[str, Any]) -> Dict[str, Any]:
        """Choose the value with the newest comparable timestamp."""
        return local if local.get("updated_at", 0) >= remote.get("updated_at", 0) else remote

    @staticmethod
    def merge_append_only(local: List[Dict[str, Any]], remote: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Merge append-only records by stable ID without duplicates."""
        merged = {str(item.get("id")): item for item in remote}
        for item in local:
            key = str(item.get("id"))
            if key in merged and merged[key].get("user_id") != item.get("user_id"):
                continue
            merged[key] = item
        return list(merged.values())