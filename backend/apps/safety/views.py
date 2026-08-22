print("SAFETY VIEWS FILE LOADED")

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from apps.users.models import CustomUser
from apps.chat.models import Chat, Message
from .models import SafetySettings, TrustedContact, UserLocation, SOSSession, LiveLocationSession
from .serializers import SafetySettingsSerializer, TrustedContactSerializer, UserLocationSerializer, SOSSessionSerializer
from django.utils import timezone

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from apps.events.models import Notification


def _broadcast_to_chat(chat_id, payload):
    """
    Send a payload to the existing per-chat WebSocket group
    (`chat_<chat_id>`, see apps/chat/consumers.py / routing.py). Only
    users currently connected to that chat's group receive it — group
    membership is already gated by ChatConsumer.connect()'s participant
    check, so this reuses the existing WS auth/authorization as-is.
    """
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return
    async_to_sync(channel_layer.group_send)(f"chat_{chat_id}", payload)


def _notify_inbox(chat, message):
    """
    Push a `chat_preview_update` event to both participants' personal
    inbox channels (see apps.chat.consumers.InboxConsumer) so the Chat
    List screen updates its preview/ordering/unread badge live for
    messages created outside ChatConsumer.receive() — e.g. the
    live-location card created below.
    """
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return
    for user_id in (chat.participant_one_id, chat.participant_two_id):
        async_to_sync(channel_layer.group_send)(f"user_{user_id}", {
            "type": "chat_preview_update",
            "chat_id": chat.id,
            "message_id": message.id,
            "sender_id": message.sender_id,
            "content": message.content,
            "message_type": message.message_type,
            "timestamp": message.timestamp.isoformat(),
        })
        
class SafetySettingsView(generics.RetrieveUpdateAPIView):
    serializer_class = SafetySettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj, created = SafetySettings.objects.get_or_create(user=self.request.user)
        return obj

    def update(self, request, *args, **kwargs):
        requested_value = request.data.get("live_location_enabled")

        if requested_value is True:
            has_trusted_contact = TrustedContact.objects.filter(
                owner=request.user
            ).exists()
            if not has_trusted_contact:
                return Response(
                    {"detail": "Add at least one trusted contact before enabling live location."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            self._start_live_location(request.user)
        elif requested_value is False:
            self._end_live_location(request.user)

        return super().update(request, *args, **kwargs)

    def _start_live_location(self, user):
        """
        Create ONE LiveLocationSession (idempotent — reuses an existing
        active session instead of duplicating it) and send ONE
        live-location card message per trusted contact. Coordinate
        updates after this never create additional messages — see
        UserLocationUpdateView.
        """
        session = LiveLocationSession.objects.filter(
            user=user, status=LiveLocationSession.Status.ACTIVE
        ).first()
        if session:
            return session

        session = LiveLocationSession.objects.create(
            user=user, status=LiveLocationSession.Status.ACTIVE
        )

        trusted_contacts = TrustedContact.objects.filter(owner=user)
        print(f"LIVE_LOC: starting share, {trusted_contacts.count()} trusted contact(s)")
        for contact in trusted_contacts:
            chat = Chat.get_or_create_chat(user, contact.trusted_user)
            print(f"LIVE_LOC: chat_id={chat.id} updated_at BEFORE={chat.updated_at}")
            message = Message.objects.create(
                chat=chat,
                sender=user,
                content="📍 Live Location",
                message_type=Message.MessageType.LIVE_LOCATION,
                live_location=session,
            )
            # Without this, Chat.updated_at never changes, and since
            # Chat.Meta.ordering = ["-updated_at"], this chat won't move to
            # the top of the list — neither live nor on a fresh reload.
            chat.save(update_fields=["updated_at"])
            chat.refresh_from_db(fields=["updated_at"])
            print(f"LIVE_LOC: chat_id={chat.id} updated_at AFTER={chat.updated_at}")

            _broadcast_to_chat(chat.id, {
                "type": "chat_message",
                "message_id": message.id,
                "chat_id": chat.id,
                "sender_id": user.id,
                "content": message.content,
                "message_type": message.message_type,
                "live_location_id": session.id,
                "live_location_status": session.status,
                "latitude": None,
                "longitude": None,
                "timestamp": message.timestamp.isoformat(),
            })
            _notify_inbox(chat, message)

        return session

    def _end_live_location(self, user):
        """
        End the user's active LiveLocationSession (if any) and notify
        connected trusted contacts via WebSocket. The historical chat
        message referencing the session is left untouched.
        """
        session = LiveLocationSession.objects.filter(
            user=user, status=LiveLocationSession.Status.ACTIVE
        ).first()
        if session:
            print(f"LIVE_LOC: reusing EXISTING active session id={session.id} — no new message will be created")
            return session
        print("LIVE_LOC: no active session found, creating a new one")

        session.status = LiveLocationSession.Status.ENDED
        session.ended_at = timezone.now()
        session.save(update_fields=["status", "ended_at", "updated_at"])

        trusted_contacts = TrustedContact.objects.filter(owner=user)
        for contact in trusted_contacts:
            chat = Chat.get_or_create_chat(user, contact.trusted_user)
            _broadcast_to_chat(chat.id, {
                "type": "live_location_ended",
                "live_location_id": session.id,
                "chat_id": chat.id,
            })

        return session

class TrustedContactListCreateView(generics.ListCreateAPIView):
    serializer_class = TrustedContactSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return TrustedContact.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class TrustedContactDeleteView(generics.DestroyAPIView):
    serializer_class = TrustedContactSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_url_kwarg = "pk"

    def get_queryset(self):
        return TrustedContact.objects.filter(owner=self.request.user)

class UserLocationUpdateView(generics.GenericAPIView):
    
    serializer_class = UserLocationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        print("LOCATION DATA RECEIVED:", request.data)
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
           print("SERIALIZER ERRORS:", serializer.errors)
           return Response(
             serializer.errors,
             status=status.HTTP_400_BAD_REQUEST
    )

        location, created = UserLocation.objects.update_or_create(
             user=request.user,
             defaults={
                 "latitude": serializer.validated_data["latitude"],
                 "longitude": serializer.validated_data["longitude"],
        },
    )

        # If live location is ON, update the SAME session's coordinates and
        # broadcast over the existing per-chat WebSocket group. This never
        # creates a new chat Message — the ONE live-location card created in
        # SafetySettingsView._start_live_location is reused for the whole
        # session.
        session = LiveLocationSession.objects.filter(
            user=request.user, status=LiveLocationSession.Status.ACTIVE
        ).first()

        if session:
            session.latitude = location.latitude
            session.longitude = location.longitude
            session.save(update_fields=["latitude", "longitude", "updated_at"])

            trusted_contacts = TrustedContact.objects.filter(owner=request.user)
            for contact in trusted_contacts:
                chat = Chat.get_or_create_chat(request.user, contact.trusted_user)
                _broadcast_to_chat(chat.id, {
                    "type": "live_location_update",
                    "live_location_id": session.id,
                    "chat_id": chat.id,
                    "latitude": str(location.latitude),
                    "longitude": str(location.longitude),
                })

        return Response(
             self.get_serializer(location).data,
             status=status.HTTP_200_OK,
    )

class TrustedUserLocationView(generics.RetrieveAPIView):
    serializer_class = UserLocationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user_id = kwargs.get("user_id")
        target_user = get_object_or_404(CustomUser, id=user_id)

        is_trusted = TrustedContact.objects.filter(
            owner=target_user, trusted_user=request.user
        ).exists()

        if not is_trusted:
            return Response(
                {"detail": "You are not a trusted contact of this user."},
                status=status.HTTP_403_FORBIDDEN,
            )

        location = UserLocation.objects.filter(user=target_user).first()
        if not location:
            return Response(
                {"detail": "Location not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = self.get_serializer(location)
        return Response(serializer.data, status=status.HTTP_200_OK)

class SOSActivateView(generics.GenericAPIView):
    serializer_class = SOSSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        has_trusted_contact = TrustedContact.objects.filter(
            owner=request.user
        ).exists()
        if not has_trusted_contact:
            return Response(
                {"detail": "Add at least one trusted contact before activating SOS."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing_session = SOSSession.objects.filter(
            user=request.user, status=SOSSession.Status.ACTIVE
        ).first()

        if existing_session:
            serializer = self.get_serializer(existing_session)
            return Response(
                {
                    "message": "SOS is already active.",
                    "sos_session": serializer.data,
                },
                status=status.HTTP_200_OK,
            )

        session = SOSSession.objects.create(
            user=request.user, status=SOSSession.Status.ACTIVE
        )

        trusted_contacts = TrustedContact.objects.filter(owner=request.user)
        for contact in trusted_contacts:
            
            Notification.objects.create(
                recipient=contact.trusted_user,
                notification_type='sos',
                title='SOS Alert',
                body=f"{request.user.full_name} has activated an SOS alert and needs help.",
            )
            print("Notification created")
        # Automatically end SOS after notifications are sent
        session.status = SOSSession.Status.ENDED
        session.ended_at = timezone.now()
        session.save()
        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class SOSDeactivateView(generics.GenericAPIView):
    serializer_class = SOSSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        session = SOSSession.objects.filter(
            user=request.user, status=SOSSession.Status.ACTIVE
        ).first()

        if not session:
            return Response(
                {"detail": "No active SOS session found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        session.status = SOSSession.Status.ENDED
        session.ended_at = timezone.now()
        session.save()

        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)