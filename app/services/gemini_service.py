"""
OpenRouter AI Service (Migration from Gemini)

Provides a reusable interface to the OpenRouter API for all agents.
Uses the nvidia/nemotron-3-super-120b-a12b:free model by default.
"""

import requests
import json
from loguru import logger
from app.config import settings

class GeminiService:
    """Wrapper around the OpenRouter generative AI client (Migration)."""

    def __init__(self):
        self.url = "https://openrouter.ai/api/v1/chat/completions"
        self.model = "nvidia/nemotron-3-super-120b-a12b:free"
        
        # Collect all configured API keys, filter empty ones and duplicates while keeping order
        raw_keys = [
            settings.openrouter_api_key,
            settings.openrouter_api_key_2,
            settings.openrouter_api_key_3
        ]
        seen = set()
        self.keys = []
        for k in raw_keys:
            if k and k.strip() and k not in seen:
                seen.add(k)
                self.keys.append(k)
                
        if not self.keys:
            logger.warning("No OpenRouter API keys configured in settings!")

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.3,
        response_mime_type: str = "application/json",
    ) -> str:
        """
        Send a prompt to OpenRouter and return the text response.
        Supports API key rotation on 429 (Rate Limit) errors.
        """
        # Try each API key in rotation
        for idx, key in enumerate(self.keys):
            try:
                # Combine system and user prompt for best results with Nemotron
                full_prompt = f"{system_prompt}\n\nContext: {user_prompt}"
                
                response = requests.post(
                    self.url,
                    headers={
                        "Authorization": f"Bearer {key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": self.model,
                        "messages": [{"role": "user", "content": full_prompt}],
                        "temperature": temperature
                    },
                    timeout=15
                )
                response.raise_for_status()
                content = response.json()["choices"][0]["message"]["content"]
                return content
            except requests.exceptions.HTTPError as he:
                # If we hit a 429 Too Many Requests, log and try next key
                if he.response is not None and he.response.status_code == 429:
                    logger.warning(
                        f"OpenRouter API key #{idx+1} hit rate limit (429). "
                        f"Rotating to next key..."
                    )
                    continue
                # For other HTTP errors, raise immediately to let agent fallback work
                logger.error(f"OpenRouter HTTP error: {he}")
                raise
            except Exception as e:
                # For transient network issues or parsing failures, raise immediately
                logger.error(f"OpenRouter API connection error: {e}")
                raise
                
        # If all keys were exhausted due to 429 errors
        logger.error("All configured OpenRouter API keys were exhausted due to 429 rate limits.")
        raise Exception("All OpenRouter API keys exhausted.")

    async def generate_text(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.5,
    ) -> str:
        """Generate a plain-text response from OpenRouter."""
        return await self.generate(system_prompt, user_prompt, temperature, "text/plain")

# Singleton
gemini_service = GeminiService()
