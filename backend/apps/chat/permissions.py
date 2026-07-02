from rest_framework import permissions

from .models import Chat, Message


class IsChatParticipant(permissions.BasePermission):
    """
    Grants access only if the requesting user is one of the two
    participants of the Chat object (or a Chat resolved from the view).
    """

    def has_object_permission(self, request, view, obj: Chat) -> bool:
        return obj.is_participant(request.user)


class IsMessageChatParticipant(permissions.BasePermission):
    """
    Grants access only if the requesting user participates in the chat
    that owns the given Message.
    """

    def has_object_permission(self, request, view, obj: Message) -> bool:
        return obj.chat.is_participant(request.user)


class IsMessageSender(permissions.BasePermission):
    """
    Grants access only if the requesting user is the sender of the
    given Message. Used for delete/edit operations.
    """

    def has_object_permission(self, request, view, obj: Message) -> bool:
        return obj.sender_id == request.user.id


class IsMessageRecipient(permissions.BasePermission):
    """
    Grants access only if the requesting user is the recipient (i.e.
    NOT the sender) of the given Message. Used for marking as read.
    """

    def has_object_permission(self, request, view, obj: Message) -> bool:
        return obj.chat.is_participant(request.user) and obj.sender_id != request.user.id