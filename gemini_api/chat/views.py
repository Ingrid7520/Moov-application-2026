# chat/views.py → VERSION FINALE AVEC IMAGES CORRIGÉES

import os
import json
import base64
import requests
import google.generativeai as genai
from django.http import StreamingHttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser, FormParser, MultiPartParser
from rest_framework import status
from PIL import Image
from io import BytesIO

# Configuration
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Stockage des conversations
ACTIVE_CHATS = {}


def build_content_and_chat(request):
    """Fonction commune : prépare le contenu et retourne le chat + content"""
    print("=" * 50)
    print("DEBUG request.body:", request.body[:100])
    print("DEBUG Content-Type:", request.content_type)
    print("=" * 50)
    
    if not request.body or request.body == b'':
        raise ValueError("Le body de la requête est vide")
    
    # Gestion intelligente : texte brut OU JSON
    user_text = None
    image_url = None
    image_b64 = None
    session_id = "default"
    
    try:
        data = request.data
        print("✅ JSON parsé:", {k: v[:50] if isinstance(v, str) and len(v) > 50 else v for k, v in data.items()})
        user_text = data.get("message", "").strip()
        image_url = data.get("image_url")
        image_b64 = data.get("image_base64")
        session_id = data.get("session_id", "default")
    except:
        print("⚠️ Pas du JSON, traitement comme texte brut")
        user_text = request.body.decode('utf-8').strip()
    
    if not user_text and not image_url and not image_b64:
        raise ValueError("Envoie un message ou une image")

    # Créer ou récupérer le chat
    if session_id not in ACTIVE_CHATS:
        model = genai.GenerativeModel(
            "gemini-2.5-flash-lite",
            system_instruction="Tu es un assistant très sympa. Tu réponds toujours en français, même avec des images."
        )
        ACTIVE_CHATS[session_id] = model.start_chat()

    chat = ACTIVE_CHATS[session_id]
    content = []

    if user_text:
        content.append(user_text)

    # ✅ TRAITEMENT IMAGE URL avec PIL
    if image_url:
        try:
            print(f"📥 Téléchargement image depuis URL: {image_url}")
            img_data = requests.get(image_url, timeout=15).content
            img = Image.open(BytesIO(img_data))
            print(f"✅ Image chargée: {img.format} {img.size}")
            content.append(img)
        except Exception as e:
            print(f"❌ Erreur téléchargement image: {e}")
            raise ValueError(f"Impossible de télécharger l'image: {str(e)}")

    # ✅ TRAITEMENT IMAGE BASE64 avec PIL
    if image_b64:
        try:
            print("📥 Décodage image base64")
            # Enlever le préfixe data:image/...;base64, si présent
            if "," in image_b64:
                image_b64 = image_b64.split(",")[1]
            
            img_data = base64.b64decode(image_b64)
            img = Image.open(BytesIO(img_data))
            print(f"✅ Image base64 chargée: {img.format} {img.size}")
            content.append(img)
        except Exception as e:
            print(f"❌ Erreur décodage image base64: {e}")
            raise ValueError(f"Image base64 invalide: {str(e)}")

    print(f"📦 Content final: {len(content)} éléments")
    return chat, content, session_id


# ===================================================================
class ChatSimpleView(APIView):
    """Pour l'interface DRF → réponse complète en JSON"""
    parser_classes = [JSONParser, FormParser, MultiPartParser]
    
    def post(self, request):
        try:
            print("🚀 ChatSimpleView appelée")
            chat, content, session_id = build_content_and_chat(request)
            print("✅ Content préparé")
            response = chat.send_message(content, stream=False)
            print("✅ Réponse Gemini reçue")
            return Response({
                "response": response.text,
                "session_id": session_id
            })
        except ValueError as e:
            print("❌ ValueError:", e)
            return Response({"error": str(e)}, status=400)
        except Exception as e:
            print("❌ Exception:", e)
            import traceback
            traceback.print_exc()
            if "quota" in str(e).lower() or "429" in str(e):
                return Response({"error": "Quota Gemini dépassé, attends 60s"}, status=429)
            return Response({"error": f"Erreur serveur: {str(e)}"}, status=500)


# ===================================================================
class ChatStreamView(APIView):
    """Streaming réel → mot par mot"""
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
            except ValueError as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
            except Exception as e:
                import traceback
                traceback.print_exc()
                error = "Quota dépassé" if ("quota" in str(e).lower() or "429" in str(e)) else str(e)
                yield f"data: {json.dumps({'error': error})}\n\n"

        return StreamingHttpResponse(event_stream(), content_type="text/event-stream")


# ===================================================================
from django.shortcuts import render

def test_stream_view(request):
    """Page de test du streaming"""
    return render(request, 'test_stream.html')