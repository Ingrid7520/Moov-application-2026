# chat/urls.py
from django.urls import path
from .views import ChatSimpleView, ChatStreamView

urlpatterns = [
    path('chat/', ChatSimpleView.as_view(), name='chat'),           # ← celle qui marche dans le navigateur
    path('chat/stream/', ChatStreamView.as_view(), name='stream'),
]