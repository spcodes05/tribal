from typing import Optional

from rest_framework import serializers

from .models import Chat, Message


class MessageSerializer(serializers.ModelSerializer):
    """Serializes individual chat messages."""

    sender_id = serializers.IntegerField(source="sender.id", read_only=True)
    live_location_id = serializers.IntegerField(
        source="live_location.id", read_only=True, default=None
    )
    live_location_status = serializers.CharField(
        source="live_location.status", read_only=True, default=None
    )
    live_location_latitude = serializers.DecimalField(
        source="live_location.latitude", max_digits=18, decimal_places=12,
        read_only=True, default=None
    )
    live_location_longitude = serializers.DecimalField(
        source="live_location.longitude", max_digits=18, decimal_places=12,
        read_only=True, default=None
    )

    class Meta:
        model = Message
        fields = [
            "id",
            "chat",
            "sender_id",
            "content",
            "message_type",
            "live_location_id",
            "live_location_status",
            "live_location_latitude",
            "live_location_longitude",
            "timestamp",
            "is_read",
            "edited_at",
        ]
        read_only_fields = [
            "id", "message_type", "live_location_id", "live_location_status",
            "live_location_latitude", "live_location_longitude",
            "timestamp", "is_read", "edited_at",
        ]


class ChatSerializer(serializers.ModelSerializer):
    """
    Full representation of a Chat, including its participants and
    ordered message history. Intended for a single-chat detail view.
    """

    messages = MessageSerializer(many=True, read_only=True)
    participant_one_id = serializers.IntegerField(
        source="participant_one.id", read_only=True
    )
    participant_two_id = serializers.IntegerField(
        source="participant_two.id", read_only=True
    )

    class Meta:
        model = Chat
        fields = [
            "id",
            "participant_one_id",
            "participant_two_id",
            "created_at",
            "updated_at",
            "messages",
        ]
        read_only_fields = fields


class ChatPreviewSerializer(serializers.ModelSerializer):
    """
    Lightweight representation of a Chat for use in a conversation list
    (inbox view). Resolves "the other user" relative to the requesting
    user, found in `self.context["request"].user`.
    """

    other_user_id = serializers.SerializerMethodField()
    other_user_full_name = serializers.SerializerMethodField()
    other_user_profile_image = serializers.SerializerMethodField()
    latest_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Chat
        fields = [
            "id",
            "other_user_id",
            "other_user_full_name",
            "other_user_profile_image",
            "latest_message",
            "unread_count",
            "updated_at",
        ]
        read_only_fields = fields

    def get_other_user_id(self, chat: Chat):
        other_user = self._get_other_user(chat)
        return other_user.id if other_user else None    

    def _get_request_user(self):
        request = self.context.get("request")
        return getattr(request, "user", None)

    def _get_other_user(self, chat: Chat):
        user = self._get_request_user()
        if user is None:
            return None
        try:
            return chat.get_other_participant(user)
        except ValueError:
            return None

    def get_other_user_full_name(self, chat: Chat) -> Optional[str]:
    
        other_user = self._get_other_user(chat)
        if other_user is None:
            return None

        return other_user.full_name

    def get_other_user_profile_image(self, chat: Chat) -> Optional[str]:
        """
        Return the other participant's profile image URL if the field
        exists on the user model and has a value. Returns None otherwise
        without assuming the field's existence.
        """
        other_user = self._get_other_user(chat)
        if other_user is None:
            return None

        image_field = getattr(other_user, "profile_image", None)
        if not image_field:
            return None

        url = getattr(image_field, "url", None)
        if url is None:
            return None

        request = self.context.get("request")
        if request is not None:
            return request.build_absolute_uri(url)
        return url

    def get_latest_message(self, chat: Chat) -> Optional[dict]:
        """Return a compact representation of the most recent message, if any."""
        latest = chat.messages.order_by("-timestamp").first()
        if latest is None:
            return None
        return {
            "id": latest.id,
            "sender_id": latest.sender_id,
            "content": latest.content,
            "message_type": latest.message_type,
            "timestamp": latest.timestamp,
            "is_read": latest.is_read,
        }

    def get_unread_count(self, chat: Chat) -> int:
        """Return the number of unread messages not sent by the requesting user."""
        user = self._get_request_user()
        if user is None:
            return 0
        return chat.messages.filter(is_read=False).exclude(sender=user).count()