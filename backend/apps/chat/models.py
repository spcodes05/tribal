from django.conf import settings
from django.db import models
from django.db.models import Q, QuerySet


class Chat(models.Model):
    """
    Represents a one-to-one conversation between exactly two users.

    Duplicate conversations between the same pair of users are prevented
    by normalizing participant order (participant_one always has the
    lower primary key) and enforcing a unique_together constraint.
    """

    participant_one = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="chats_as_participant_one",
        on_delete=models.CASCADE,
    )
    participant_two = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="chats_as_participant_two",
        on_delete=models.CASCADE,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("participant_one", "participant_two")
        ordering = ["-updated_at"]
        indexes = [
            models.Index(fields=["participant_one", "participant_two"]),
        ]

    def __str__(self) -> str:
        return f"Chat({self.participant_one_id}, {self.participant_two_id})"

    @classmethod
    def get_or_create_chat(cls, user_a, user_b) -> "Chat":
        """
        Return the existing chat between user_a and user_b, creating one
        if it does not exist. Participant order is normalized by primary
        key to guarantee uniqueness regardless of argument order.
        """
        if user_a.pk == user_b.pk:
            raise ValueError("A chat requires two distinct users.")

        first, second = sorted([user_a, user_b], key=lambda u: u.pk)
        chat, _created = cls.objects.get_or_create(
            participant_one=first,
            participant_two=second,
        )
        return chat

    @classmethod
    def for_user(cls, user) -> QuerySet["Chat"]:
        """Return all chats that the given user participates in."""
        return cls.objects.filter(
            Q(participant_one=user) | Q(participant_two=user)
        )

    def get_other_participant(self, user):
        """Return the participant in this chat who is not `user`."""
        if user.pk == self.participant_one_id:
            return self.participant_two
        if user.pk == self.participant_two_id:
            return self.participant_one
        raise ValueError("User is not a participant of this chat.")

    def is_participant(self, user) -> bool:
        """Return True if `user` is one of the two participants."""
        return user.pk in (self.participant_one_id, self.participant_two_id)


class Message(models.Model):
    """
    A single message sent within a Chat. Messages are hard-deleted when
    their parent Chat is deleted (via CASCADE).
    """

    chat = models.ForeignKey(
        Chat,
        related_name="messages",
        on_delete=models.CASCADE,
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="sent_messages",
        on_delete=models.CASCADE,
    )
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    edited_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["timestamp"]
        indexes = [
            models.Index(fields=["chat", "timestamp"]),
        ]

    def __str__(self) -> str:
        return f"Message({self.sender_id} -> chat {self.chat_id})"

    def mark_as_read(self) -> None:
        """Mark this message as read, persisting only the changed field."""
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=["is_read"])

    def mark_edited(self) -> None:
        """Timestamp this message as edited, persisting only that field."""
        from django.utils import timezone

        self.edited_at = timezone.now()
        self.save(update_fields=["edited_at"])