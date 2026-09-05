"""Conversational AI endpoint for Smriti Voice Assistant."""

import logging
from fastapi import APIRouter, HTTPException
from app.core.config import settings
from app.schemas.api import VoiceChatRequest, VoiceChatResponse
from app.services.content_guard import passes_content_guard

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/voice", tags=["voice"])


def _generate_fallback_response(message: str, history: list, language: str) -> str:
    """Provide a warm, supportive, elderly-tailored response when generative AI is unconfigured."""
    lower = message.lower().strip()
    lang_clean = language.lower()

    # Telugu fallback
    if "te" in lang_clean or "telugu" in lang_clean:
        if any(w in lower for w in ["ఎలా ఉన్నారు", "బాగున్నారా"]):
            return "నేను బాగున్నాను. మీకు సహాయం చేయడానికి సిద్ధంగా ఉన్నాను. మీరు ఎలా ఉన్నారు?"
        if any(w in lower for w in ["నమస్కారం", "హలో"]):
            return "నమస్కారం! నేను స్మృతిని. మీకు ఎలా సహాయపడగలను?"
        return "నేను విన్నాను. మీతో మాట్లాడటం నాకు చాలా సంతోషంగా ఉంది."

    # Hindi fallback
    if "hi" in lang_clean or "hindi" in lang_clean:
        if any(w in lower for w in ["कैसे हो", "कैसी हो", "कैसा चल रहा"]):
            return "मैं बिल्कुल ठीक हूँ। आपकी सेवा के लिए हमेशा तैयार हूँ। आप कैसे हैं?"
        if any(w in lower for w in ["नमस्ते", "हेलो", "प्रणाम"]):
            return "नमस्ते! मैं स्मृति हूँ। आज मैं आपकी क्या मदद कर सकती हूँ?"
        return "मैंने सुना। आपसे बात करके मुझे बहुत खुशी मिली।"

    # English fallback
    if any(w in lower for w in ["how are you", "how are you doing", "how do you do"]):
        return "I am doing well, thank you for asking! How are you feeling today?"
    if any(w in lower for w in ["hello", "hi", "hey"]):
        return "Hello! I am Smriti, your companion. How can I help you today?"
    if any(w in lower for w in ["thank you", "thanks"]):
        return "You are very welcome! It is always my pleasure to assist you."

    return "I hear you, and I am glad to be here chatting with you. What else would you like to share?"


@router.post("/chat", response_model=VoiceChatResponse)
async def voice_chat(request: VoiceChatRequest) -> VoiceChatResponse:
    """Conversational voice chat endpoint for elderly companionship."""
    clean_message = request.message.strip()
    if not clean_message:
        raise HTTPException(status_code=422, detail="Message cannot be empty")

    logger.info("[VOICE-CHAT] User query received: '%s' (lang: %s)", clean_message, request.language)

    # 1. Attempt Gemini Generative AI if key is configured
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-1.5-flash")

            system_instruction = (
                f"You are Smriti, a warm, patient, kind voice companion for an elderly person. "
                f"Respond concisely in 1-2 short, comforting sentences (under 35 words) in the requested language ({request.language}). "
                "Keep your tone gentle, respectful, and easy to understand when spoken aloud. "
                "Never mention illness, dementia, loss, death, doctor, or medical diagnoses."
            )

            # Build conversational context from recent history
            conversation_context = system_instruction + "\n\nRecent conversation:\n"
            for h in request.history[-4:]:
                role_label = "User" if h.role == "user" else "Assistant"
                conversation_context += f"{role_label}: {h.content}\n"
            conversation_context += f"User: {clean_message}\nAssistant:"

            candidate = model.generate_content(conversation_context).text.strip()
            passed, _ = passes_content_guard(candidate)
            if passed and candidate:
                logger.info("[VOICE-CHAT] Gemini generated reply: '%s'", candidate)
                return VoiceChatResponse(response=candidate)
        except Exception as e:
            logger.warning("[VOICE-CHAT] Gemini generation failed (%s), falling back to offline companion", e)

    # 2. Contextual elderly-friendly fallback
    fallback_text = _generate_fallback_response(clean_message, request.history, request.language)
    logger.info("[VOICE-CHAT] Fallback companion reply: '%s'", fallback_text)
    return VoiceChatResponse(response=fallback_text)
