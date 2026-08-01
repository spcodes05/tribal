from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from apps.users.models import CustomUser
from .models import SafetySettings, TrustedContact, UserLocation, SOSSession
from .serializers import SafetySettingsSerializer, TrustedContactSerializer, UserLocationSerializer, SOSSessionSerializer


class SafetySettingsView(generics.RetrieveUpdateAPIView):
    serializer_class = SafetySettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj, created = SafetySettings.objects.get_or_create(user=self.request.user)
        return obj

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
        obj, created = UserLocation.objects.get_or_create(
            user=request.user,
            defaults={
                "latitude": request.data.get("latitude"),
                "longitude": request.data.get("longitude"),
            },
        )
        if not created:
            serializer = self.get_serializer(obj, data=request.data, partial=True)
        else:
            serializer = self.get_serializer(obj)

        serializer.is_valid(raise_exception=True) if not created else None
        if not created:
            serializer.save()

        return Response(self.get_serializer(obj).data, status=status.HTTP_200_OK)

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
        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_201_CREATED)