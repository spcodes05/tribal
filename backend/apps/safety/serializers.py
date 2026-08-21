from rest_framework import serializers
from .models import SafetySettings, TrustedContact, UserLocation, SOSSession, LiveLocationSession
from django.contrib.auth import get_user_model
from apps.users.serializer_mixins import ProfileImageMixin


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


class TrustedUserDetailSerializer(ProfileImageMixin, serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    profile_image = serializers.SerializerMethodField()

    class Meta:
        model = get_user_model()
        fields = ["id", "full_name", "email", "profile_image"]

    def get_full_name(self, obj):
       return obj.full_name

    def get_profile_image(self, obj):
        return self.build_profile_image_url(obj)


class TrustedContactSerializer(serializers.ModelSerializer):
    trusted_user_detail = TrustedUserDetailSerializer(source="trusted_user", read_only=True)

    class Meta:
        model = TrustedContact
        fields = [
            "id",
            "owner",
            "trusted_user",
            "trusted_user_detail",
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
            "latitude",
            "longitude",
        ]
        read_only_fields = ["id"]


class LiveLocationSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = LiveLocationSession
        fields = [
            "id",
            "user",
            "status",
            "latitude",
            "longitude",
            "started_at",
            "updated_at",
            "ended_at",
        ]
        read_only_fields = ["id", "user", "started_at", "updated_at"]


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