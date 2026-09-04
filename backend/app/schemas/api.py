"""Canonical request and response models for the mobile API."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class GameSessionRequest(BaseModel):
    game_code: str
    client_generated_id: str | None = None


class AttemptRequest(BaseModel):
    session_id: str
    selected_index: int = Field(ge=0)
    response_time_ms: int = Field(ge=0)


class JournalEntryRequest(BaseModel):
    photo_url: str | None = None
    voice_note_url: str | None = None
    tag_place: str | None = None
    tag_object: str | None = None
    tag_occasion: str | None = None
    caption: str | None = None
    ai_story_text: str | None = None
    ai_story_passed_content_guard: bool = False


class StoryRequest(BaseModel):
    entry_ids: list[str] = Field(default_factory=list)


class StoryAction(BaseModel):
    action: str


class GenerateStoryRequest(BaseModel):
    title: str | None = None
    content: str | None = None
    language: str = "English"


class GenerateStoryResponse(BaseModel):
    story: str


class ReminderRequest(BaseModel):
    label: str
    type: str
    scheduled_time: datetime


class SyncRecord(BaseModel):
    collection: str
    client_generated_id: str = Field(min_length=1)
    data: dict[str, Any] = Field(default_factory=dict)


class SyncRequest(BaseModel):
    records: list[SyncRecord] = Field(default_factory=list)


class SyncResult(BaseModel):
    client_generated_id: str
    status: str
    error: str | None = None


class SyncResponse(BaseModel):
    results: list[SyncResult]
    successful_record_ids: list[str]
