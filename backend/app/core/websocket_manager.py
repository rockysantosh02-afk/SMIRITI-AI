"""In-process websocket connection manager for caregiver alerts."""

from typing import Any, Dict, Set

from fastapi import WebSocket


class WebSocketManager:
    """Track connections by patient and broadcast JSON events."""

    def __init__(self) -> None:
        self._connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, patient_id: str, websocket: WebSocket) -> None:
        """Accept and register a websocket for a patient."""
        await websocket.accept()
        self._connections.setdefault(patient_id, set()).add(websocket)

    def disconnect(self, patient_id: str, websocket: WebSocket) -> None:
        """Remove a websocket connection."""
        connections = self._connections.get(patient_id)
        if connections is not None:
            connections.discard(websocket)
            if not connections:
                self._connections.pop(patient_id, None)

    async def broadcast(self, patient_id: str, message: Dict[str, Any]) -> None:
        """Send an alert to all connected caregivers for a patient."""
        stale = []
        for websocket in self._connections.get(patient_id, set()):
            try:
                await websocket.send_json(message)
            except Exception:
                stale.append(websocket)
        for websocket in stale:
            self.disconnect(patient_id, websocket)


websocket_manager = WebSocketManager()
