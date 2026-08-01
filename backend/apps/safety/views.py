from rest_framework import generics, permissions
from .models import SafetySettings
from .serializers import SafetySettingsSerializer


class SafetySettingsView(generics.RetrieveUpdateAPIView):
    serializer_class = SafetySettingsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj, created = SafetySettings.objects.get_or_create(user=self.request.user)
        return obj