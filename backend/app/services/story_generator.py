"""AI generation helpers for the Personal Memory Journal."""

from typing import Any, Dict, List

from app.core.config import settings
from app.services.content_guard import guard_content, passes_content_guard


def generate_story_from_memory(
    title: str | None,
    content: str | None,
    language: str = "English",
    return_source: bool = False,
) -> str | tuple[str, str]:
    """Generate a warm, short, encouraging AI story from journal title and content."""
    clean_title = (title or "").strip()
    clean_content = (content or "").strip()
    topic = clean_title or clean_content or "this special day"

    prompt = (
        f"You are a gentle, encouraging companion for an elderly person. "
        f"Write a warm, simple, first-person reflection in {language} in 2-4 short sentences (under 60 words). "
        f"Theme: Title: {clean_title or 'A Treasured Moment'}, Details: {clean_content or 'A happy time'}. "
        "Keep the tone peaceful, nostalgic, and emotionally uplifting. "
        "Do NOT mention illness, dementia, loss, death, doctor, medication, or medical diagnoses."
    )

    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")
            candidate = model.generate_content(prompt).text.strip()
            passed, _ = passes_content_guard(candidate)
            if passed:
                return (candidate, "ai") if return_source else candidate
        except Exception:
            pass

    # Language-aware gentle templates
    lang_lower = language.lower()
    if "assam" in lang_lower or lang_lower == "as":
        text = (
            f"মই এই স্মৃতিটো বৰ মৰমেৰে সোঁৱৰণ কৰোঁ। "
            f"{topic} মনত পেলালে মনটো আনন্দ আৰু শান্তিত ভৰি পৰে। "
            f"প্ৰতিটো স্মৃতি হৃদয়ৰ এটি আপুৰুগীয়া সম্পদ।"
        )
    elif "bengal" in lang_lower or lang_lower == "bn":
        text = (
            f"আমি এই স্মৃতিটি অত্যন্ত স্নেহের সাথে মনে রাখি। "
            f"{topic} মনে পড়লেই মনটা শান্তি ও আনন্দে ভরে ওঠে। "
            f"প্রতিটি স্মৃতি হৃদয়ের এক অমূল্য সম্পদ।"
        )
    elif "hindi" in lang_lower or lang_lower == "hi":
        text = (
            f"मैं इस प्यारी याद को हमेशा संजो कर रखता हूँ। "
            f"{topic} को याद करके मन में सुखद शांति भर जाती है। "
            f"यह एक बेहद सुंदर और अनमोल स्मृति है।"
        )
    else:
        text = (
            f"I cherish this beautiful memory dearly. "
            f"Thinking back to {topic} brings a gentle warmth and peace to my heart. "
            f"Every memory we treasure remains a lovely gift in our lives."
        )

    passed, _ = passes_content_guard(text)
    if not passed:
        fallback_safe = "Every memory we keep is a precious part of our journey. Remembering this brings peace and warmth to my heart."
        return (fallback_safe, "fallback") if return_source else fallback_safe
    return (text, "fallback") if return_source else text


def generate_journal_story(caption: str | None, tag_place: str | None, tag_occasion: str | None, language: str = "English") -> str:
    """Generate a short, factual first-person reflection from journal fields."""
    prompt = (
        f"Write a warm first-person reflection in {language} in 3-5 sentences and under 60 words. "
        "Use only the supplied facts. Never invent facts, mention illness or death, or use a negative tone. "
        f"Caption: {caption or 'not provided'}; place: {tag_place or 'not provided'}; "
        f"occasion: {tag_occasion or 'not provided'}."
    )
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")
            return model.generate_content(prompt).text.strip()
        except Exception:
            pass
    place = tag_place or "this special place"
    occasion = f" during {tag_occasion}" if tag_occasion else ""
    return f"I remember {caption or 'this lovely moment'}{occasion}. It brings a warm feeling whenever I think of {place}."


def generate_recall_quiz(journal_entries: list[dict]) -> list[dict]:
    """Create recall questions from the user's own journal tags."""
    questions: list[dict] = []
    for entry in journal_entries:
        place = entry.get("tag_place")
        occasion = entry.get("tag_occasion")
        object_tag = entry.get("tag_object")
        if place:
            options = [place] + [str(item.get("tag_place")) for item in journal_entries if item.get("tag_place") and item.get("tag_place") != place][:2]
            questions.append({"prompt": "What did you call this place?", "options": options, "expected_answer": place})
        if occasion:
            options = [occasion] + [str(item.get("tag_occasion")) for item in journal_entries if item.get("tag_occasion") and item.get("tag_occasion") != occasion][:2]
            questions.append({"prompt": "What occasion did you tag?", "options": options, "expected_answer": occasion})
        if object_tag:
            questions.append({"prompt": "What object did you remember?", "options": [object_tag, "something else"], "expected_answer": object_tag})
    return questions


def generate_story(entries: List[Dict[str, Any]]) -> str:
    """Generate a safe story from the user's journal entries."""
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = f"Write a warm, factual personal journal story from these entries: {entries}"
            return guard_content(model.generate_content(prompt).text)
        except Exception:
            pass
    captions = ", ".join(str(entry.get("caption") or entry.get("tag_occasion") or "a cherished moment") for entry in entries)
    return guard_content(f"A cherished journal memory: {captions or 'a moment worth remembering.'}")
