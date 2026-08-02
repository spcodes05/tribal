print("SAFETY VIEWS FILE LOADED")

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from apps.users.models import CustomUser
from apps.chat.models import Chat, Message
from .models import SafetySettings, TrustedContact, UserLocation, SOSSession
from .serializers import SafetySettingsSerializer, TrustedContactSerializer, UserLocationSerializer, SOSSessionSerializer
from django.utils import timezone

from apps.events.models import Notification

class SafetySettingsView(generics.RetrieveUpdateAPIView):
    serializer_class = SafetySettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj, created = SafetySettings.objects.get_or_create(user=self.request.user)
        return obj

    def update(self, request, *args, **kwargs):
        if request.data.get("live_location_enabled") is True:
            has_trusted_contact = TrustedContact.objects.filter(
                owner=request.user
            ).exists()
            if not has_trusted_contact:
                return Response(
                    {"detail": "Add at least one trusted contact before enabling live location."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        return super().update(request, *args, **kwargs)

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

        trusted_contacts = TrustedContact.objects.filter(owner=request.user)

        print("USER SENDING LOCATION:", request.user.id)
        print("TRUSTED CONTACT COUNT:", trusted_contacts.count())
        for contact in trusted_contacts:
            chat = Chat.get_or_create_chat(request.user, contact.trusted_user)
            print("CHAT ID:", chat.id)
            Message.objects.create(
                chat=chat,
                sender=request.user,
                content=(
                    "📍 Live Location Update\n"
                    f"Latitude: {location.latitude}\n"
                    f"Longitude: {location.longitude}\n"
                    "This is an automatic location update."
                ),
            )

            print("LOCATION MESSAGE CREATED")

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