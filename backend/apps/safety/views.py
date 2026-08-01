from rest_framework import generics, permissions, status
from .models import SafetySettings
from .serializers import SafetySettingsSerializer
from rest_framework.response import Response
from .models import TrustedContact
from .serializers import TrustedContactSerializer


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