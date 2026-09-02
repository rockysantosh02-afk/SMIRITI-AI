"""Story generation adapter for Memory Vault."""

from typing import Any, Dict, List

from app.core.config import settings
from app.services.content_guard import guard_content


def generate_story(persons: List[Dict[str, Any]], events: List[Dict[str, Any]]) -> str:
    """Generate a safe memory story, using Gemini when configured."""
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = f"Write a warm, factual family memory story from these people and events: {persons}; {events}"
            return guard_content(model.generate_content(prompt).text)
        except Exception:
            pass
    names = ", ".join(str(person.get("name", "a loved one")) for person in persons) or "your loved ones"
    return guard_content(f"A cherished memory with {names}, shared with warmth and care.")
