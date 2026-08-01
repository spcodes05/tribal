from rest_framework import serializers
from .models import SafetySettings, TrustedContact, UserLocation, SOSSession


class SafetySettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetySettings
        fields = [
            "id",
            "user",
            "live_location_enabled",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]


class TrustedContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrustedContact
        fields = [
            "id",
            "owner",
            "trusted_user",
            "created_at",
        ]
        read_only_fields = ["id", "owner", "created_at"]

    def validate(self, attrs):
        request = self.context.get("request")
        owner = request.user if request else attrs.get("owner")
        trusted_user = attrs.get("trusted_user")

        if owner and trusted_user and owner == trusted_user:
            raise serializers.ValidationError(
                "You cannot add yourself as a trusted contact."
            )

        if owner and trusted_user:
            if TrustedContact.objects.filter(
                owner=owner, trusted_user=trusted_user
            ).exists():
                raise serializers.ValidationError(
                    "This user is already added as a trusted contact."
                )

        return attrs


class UserLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserLocation
        fields = [
            "id",
            "user",
            "latitude",
            "longitude",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "updated_at"]


class SOSSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SOSSession
        fields = [
            "id",
            "user",
            "status",
            "started_at",
            "ended_at",
        ]
        read_only_fields = ["id", "user", "started_at"]