# chat/views.py

import os
import json
import base64
import requests
import mimetypes
import google.generativeai as genai
from django.http import StreamingHttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser, FormParser, MultiPartParser
from PIL import Image
from io import BytesIO

from google.api_core.exceptions import ResourceExhausted, ServiceUnavailable, InternalServerError, DeadlineExceeded

# Configuration Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Stockage des sessions de chat
ACTIVE_CHATS = {}

# System instruction optimisée et concise
system_instruction = """
Tu es AgriSmart, un assistant IA expert en agriculture intelligente et durable, spécialisé dans l'accompagnement des agriculteurs ivoiriens et tropicaux (climat chaud, cultures comme le cacao, café, riz, maïs, manioc, légumes, élevage).

Ton ton est amical, encourageant, positif et très direct. Tu tutoies l'utilisateur ("tu", "ton champ", etc.). Tu réponds EXCLUSIVEMENT en français simple et clair.

Règle la plus importante : SOIS TOUJOURS CONCIS. 
Les agriculteurs ont peu de temps et de data. Évite les longues introductions, les phrases inutiles et le bavardage. Va droit au but.

Structure obligatoire de tes réponses :
1. Reformule brièvement la question (1 phrase max).
2. Donne la réponse principale directement.
3. Si besoin, liste les conseils en puces courtes (max 5 points).
4. Pose une question courte seulement si nécessaire.

Quand il y a une photo : décris rapidement ce que tu vois, identifie le problème, donne 2-3 solutions (priorité naturelle).
Quand il y a une note vocale : transcris brièvement et réponds directement.

Reste pratique et efficace. Pas de longues phrases motivantes inutiles.
Si sujet hors agriculture : dis-le poliment.
"""

def build_content_and_chat(request):
    user_text = ""
    session_id = "default"
    content = []

    # === Mode multipart (Flutter) ===
    if request.content_type and 'multipart/form-data' in request.content_type:
        user_text = request.POST.get("message", "").strip()
        session_id = request.POST.get("session_id", "default")

        if user_text:
            content.append(user_text)

        # Image
        if 'image' in request.FILES:
            img_file = request.FILES['image']
            try:
                img = Image.open(img_file)
                content.append(img)
            except Exception as e:
                raise ValueError(f"Image invalide: {e}")

        # Audio
        if 'audio' in request.FILES:
            audio_file = request.FILES['audio']
            audio_data = audio_file.read()
            mime_type, _ = mimetypes.guess_type(audio_file.name)
            if not mime_type or not mime_type.startswith("audio/"):
                mime_type = "audio/m4a"
            content.append({"mime_type": mime_type, "data": audio_data})

    # === Mode JSON (web) ===
    else:
        try:
            data = json.loads(request.body)
        except:
            data = {}

        user_text = data.get("message", "").strip()
        session_id = data.get("session_id", "default")
        image_url = data.get("image_url")
        image_b64 = data.get("image_base64")
        audio_url = data.get("audio_url")
        audio_b64 = data.get("audio_base64")

        if user_text:
            content.append(user_text)

        if image_url:
            try:
                img_data = requests.get(image_url, timeout=15).content
                img = Image.open(BytesIO(img_data))
                content.append(img)
            except Exception as e:
                raise ValueError(f"Impossible de télécharger l'image: {e}")

        if image_b64:
            try:
                if "," in image_b64:
                    image_b64 = image_b64.split(",")[1]
                img_data = base64.b64decode(image_b64)
                img = Image.open(BytesIO(img_data))
                content.append(img)
            except Exception as e:
                raise ValueError(f"Image base64 invalide: {e}")

        if audio_url:
            try:
                audio_data = requests.get(audio_url, timeout=30).content
                mime_type, _ = mimetypes.guess_type(audio_url)
                if not mime_type or not mime_type.startswith("audio/"):
                    mime_type = "audio/mpeg"
                content.append({"mime_type": mime_type, "data": audio_data})
            except Exception as e:
                raise ValueError(f"Impossible de télécharger l'audio: {e}")

        if audio_b64:
            try:
                if "," in audio_b64:
                    audio_b64 = audio_b64.split(",")[1]
                audio_data = base64.b64decode(audio_b64)
                content.append({"mime_type": "audio/mpeg", "data": audio_data})
            except Exception as e:
                raise ValueError(f"Audio base64 invalide: {e}")

    if not content:
        raise ValueError("Envoie un message, une photo ou une note vocale.")

    # Création ou récupération du chat
    if session_id not in ACTIVE_CHATS:
        model = genai.GenerativeModel(
            "gemini-2.5-flash-lite",  # Plus stable pour les quotas
            system_instruction=system_instruction,
        )
        ACTIVE_CHATS[session_id] = model.start_chat()

    chat = ACTIVE_CHATS[session_id]
    return chat, content, session_id


class ChatSimpleView(APIView):
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def post(self, request):
        try:
            chat, content, session_id = build_content_and_chat(request)
            response = chat.send_message(content, stream=False)
            return Response({
                "response": response.text,
                "session_id": session_id
            })
        except ValueError as e:
            return Response({"error": str(e)}, status=400)
        except ResourceExhausted:
            return Response({"error": "⚠️ Limite quotidienne atteinte. Réessaie demain."}, status=429)
        except Exception as e:
            return Response({"error": "❌ Erreur temporaire du serveur IA."}, status=500)


class ChatStreamView(APIView):
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def post(self, request):
        def event_stream():
            try:
                chat, content, session_id = build_content_and_chat(request)
                response = chat.send_message(content, stream=True)

                for chunk in response:
                    if chunk.text:
                        yield f"data: {json.dumps({'text': chunk.text})}\n\n"

                yield "data: [DONE]\n\n"

            except ResourceExhausted:
                error_msg = "⚠️ Limite quotidienne atteinte.\nRéessaie demain ou dans quelques heures. Merci pour ta patience !"
                yield f"data: {json.dumps({'error': error_msg})}\n\n"

            except (ServiceUnavailable, InternalServerError, DeadlineExceeded) as e:
                if "overloaded" in str(e).lower():
                    error_msg = "⏳ Serveur IA temporairement surchargé.\nRéessaie dans quelques minutes."
                else:
                    error_msg = "❌ Erreur temporaire du serveur IA.\nRéessaie bientôt."
                yield f"data: {json.dumps({'error': error_msg})}\n\n"

            except ValueError as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"

            except Exception as e:
                error_msg = "❌ Une erreur est survenue. Réessaie plus tard."
                yield f"data: {json.dumps({'error': error_msg})}\n\n"

        return StreamingHttpResponse(event_stream(), content_type="text/event-stream")