from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Chat, Message
from .permissions import (
    IsChatParticipant,
    IsMessageRecipient,
    IsMessageSender,
)
from .serializers import ChatPreviewSerializer, MessageSerializer

User = get_user_model()


class ChatListView(generics.ListAPIView):
    """GET /api/chat/ — every conversation belonging to the requesting user."""

    serializer_class = ChatPreviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Chat.for_user(self.request.user)
            .select_related("participant_one", "participant_two")
            .prefetch_related("messages")
            .order_by("-updated_at")
        )


class ChatMessageListView(generics.ListAPIView):
    """GET /api/chat/<chat_id>/ — every message in a conversation, oldest first."""

    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated, IsChatParticipant]

    def get_chat(self) -> Chat:
        chat = get_object_or_404(Chat, pk=self.kwargs["chat_id"])
        self.check_object_permissions(self.request, chat)
        return chat

    def get_queryset(self):
        chat = self.get_chat()
        return (
            chat.messages.select_related("sender", "chat")
            .order_by("timestamp")
        )


class StartChatView(APIView):
    """POST /api/chat/start/ — return an existing chat or create a new one."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user_id = request.data.get("user_id")
        if user_id is None:
            raise ValidationError({"user_id": "This field is required."})

        try:
            user_id = int(user_id)
        except (TypeError, ValueError):
            raise ValidationError({"user_id": "Must be a valid integer."})

        if user_id == request.user.id:
            raise ValidationError({"user_id": "You cannot start a chat with yourself."})

        other_user = get_object_or_404(User, pk=user_id)

        chat = Chat.get_or_create_chat(request.user, other_user)
        serializer = ChatPreviewSerializer(chat, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class SendMessageView(APIView):
    """POST /api/chat/<chat_id>/send/ — create a new message in a conversation."""

    permission_classes = [permissions.IsAuthenticated, IsChatParticipant]

    def post(self, request, chat_id, *args, **kwargs):
        chat = get_object_or_404(Chat, pk=chat_id)
        self.check_object_permissions(request, chat)

        content = request.data.get("content", "")
        if isinstance(content, str):
            content = content.strip()
        if not content:
            raise ValidationError({"content": "Message content cannot be empty."})

        message = Message.objects.create(
            chat=chat,
            sender=request.user,
            content=content,
        )
        chat.save(update_fields=["updated_at"])

        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MarkMessageReadView(APIView):
    """PATCH /api/chat/message/<message_id>/read/ — recipient marks a message as read."""

    permission_classes = [permissions.IsAuthenticated, IsMessageRecipient]

    def patch(self, request, message_id, *args, **kwargs):
        message = get_object_or_404(
            Message.objects.select_related("chat", "sender"), pk=message_id
        )
        self.check_object_permissions(request, message)

        message.mark_as_read()

        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_200_OK)


class DeleteMessageView(APIView):
    """DELETE /api/chat/message/<message_id>/ — sender deletes their own message."""

    permission_classes = [permissions.IsAuthenticated, IsMessageSender]

    def delete(self, request, message_id, *args, **kwargs):
        message = get_object_or_404(
            Message.objects.select_related("chat", "sender"), pk=message_id
        )
        self.check_object_permissions(request, message)

        message.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)