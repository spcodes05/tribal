from django.urls import path

from .views import (
    ChatListView,
    ChatMessageListView,
    DeleteMessageView,
    MarkMessageReadView,
    SendMessageView,
    StartChatView,
)

app_name = "chat"

urlpatterns = [
    path("start/", StartChatView.as_view(), name="chat-start"),
    path(
        "message/<int:message_id>/read/",
        MarkMessageReadView.as_view(),
        name="message-read",
    ),
    path(
        "message/<int:message_id>/",
        DeleteMessageView.as_view(),
        name="message-delete",
    ),
    path("<int:chat_id>/send/", SendMessageView.as_view(), name="chat-send"),
    path("<int:chat_id>/", ChatMessageListView.as_view(), name="chat-messages"),
    path("", ChatListView.as_view(), name="chat-list"),
]