import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer

from .models import Chat, Message


class ChatConsumer(AsyncWebsocketConsumer):
    """
    Real-time messaging consumer for a single chat room.

    Responsibilities:
        - Authenticate and authorize the connecting user.
        - Receive new message payloads and persist them.
        - Broadcast newly created messages to both participants.

    Explicitly NOT responsible for:
        - Loading message history (handled by REST).
        - Creating/looking up chats (handled by REST).
        - Marking messages as read or deleting them (handled by REST).
    """

    async def connect(self):
        print("===== CONNECT() CALLED =====")

        self.user = self.scope.get("user")
        self.chat_id = self.scope["url_route"]["kwargs"].get("chat_id")

        print("USER:", self.user)
        print("AUTH:", getattr(self.user, "is_authenticated", None))
        print("CHAT_ID:", self.chat_id)

        self.group_name = f"chat_{self.chat_id}"

        if self.user is None or not self.user.is_authenticated:
            print("REJECT: NOT AUTHENTICATED")
            await self.close(code=4001)
            return
        
        print("CONNECTED USER:", self.scope["user"])

        chat = await self._get_chat(self.chat_id)
        print("CHAT:", chat)

        if chat is None:
            print("REJECT: CHAT NOT FOUND")
            await self.close(code=4004)
            return

        allowed = await self._user_is_participant(chat, self.user)
        print("IS PARTICIPANT:", allowed)

        if not allowed:
            print("REJECT: NOT PARTICIPANT")
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code) -> None:
        if getattr(self, "group_name", None):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None) -> None:
        try:
            payload = json.loads(text_data or "{}")
        except (TypeError, json.JSONDecodeError):
            await self._send_error("Invalid JSON payload.")
            return

        content = payload.get("content", "")
        if isinstance(content, str):
            content = content.strip()

        if not content:
            await self._send_error("Message content cannot be empty.")
            return

        try:
            message = await self._create_message(self.chat_id, self.user, content)
        except Chat.DoesNotExist:
            await self._send_error("Chat no longer exists.")
            return
        except Exception:
            await self._send_error("Failed to send message.")
            return

        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "chat_message",
                "message_id": message.id,
                "chat_id": message.chat_id,
                "sender_id": message.sender_id,
                "content": message.content,
                "timestamp": message.timestamp.isoformat(),
            },
        )

    async def chat_message(self, event: dict) -> None:
        """Handler for the 'chat_message' group event type; pushes to the client."""
        await self.send(text_data=json.dumps(event))

    async def _send_error(self, detail: str) -> None:
        await self.send(text_data=json.dumps({"type": "error", "detail": detail}))

    @database_sync_to_async
    def _get_chat(self, chat_id):
        return Chat.objects.filter(pk=chat_id).first()

    @database_sync_to_async
    def _user_is_participant(self, chat: Chat, user) -> bool:
        return chat.is_participant(user)

    @database_sync_to_async
    def _create_message(self, chat_id, sender, content: str) -> Message:
        chat = Chat.objects.get(pk=chat_id)
        message = Message.objects.create(chat=chat, sender=sender, content=content)
        chat.save(update_fields=["updated_at"])
        return message