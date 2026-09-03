"""In-process websocket connection manager for user notifications."""

from typing import Any, Dict, Set

from fastapi import WebSocket


class WebSocketManager:
    """Track connections by user and broadcast JSON events."""

    def __init__(self) -> None:
        self._connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket) -> None:
        """Accept and register a websocket for a user."""
        await websocket.accept()
        self._connections.setdefault(user_id, set()).add(websocket)

    def disconnect(self, user_id: str, websocket: WebSocket) -> None:
        """Remove a websocket connection."""
        connections = self._connections.get(user_id)
        if connections is not None:
            connections.discard(websocket)
            if not connections:
                self._connections.pop(user_id, None)

    async def broadcast(self, user_id: str, message: Dict[str, Any]) -> None:
        """Send a notification to the user's connections."""
        stale = []
        for websocket in self._connections.get(user_id, set()):
            try:
                await websocket.send_json(message)
            except Exception:
                stale.append(websocket)
        for websocket in stale:
            self.disconnect(user_id, websocket)


websocket_manager = WebSocketManager()
