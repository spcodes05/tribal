from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Activity, ActivityMember, Notification

User = get_user_model()


# ── Nested host summary used inside ActivitySerializer ───────────────────────

class HostSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'is_email_verified']


# ── Member summary (stacked avatars on card) ─────────────────────────────────

class MemberSerializer(serializers.ModelSerializer):
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)

    class Meta:
        model = ActivityMember
        fields = ['user_id', 'full_name', 'joined_at']


# ── Activity list card (compact, for home screen) ─────────────────────────────

class ActivityCardSerializer(serializers.ModelSerializer):
    host_name = serializers.CharField(source='host.full_name', read_only=True)
    member_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)

    # Distance from user — computed in the view using a simple query
    # (no PostGIS needed: we store location as string + compute a stub
    # distance for the MVP, can be replaced with haversine later).
    distance_km = serializers.SerializerMethodField()

    # Match percent — computed in view based on shared interests
    match_percent = serializers.SerializerMethodField()

    def get_distance_km(self, obj):
        # Stub: return the value injected by the view via context
        distances = self.context.get('distances', {})
        return distances.get(obj.id, None)

    def get_match_percent(self, obj):
        match_percents = self.context.get('match_percents', {})
        return match_percents.get(obj.id, None)

    class Meta:
        model = Activity
        fields = [
            'id', 'title', 'image_url', 'location',
            'date', 'time',
            'is_women_only', 'is_accessible', 'is_free',
            'member_count', 'max_members', 'is_full',
            'host_name', 'distance_km', 'match_percent',
        ]


# ── Activity detail (full, for activity detail screen) ────────────────────────

class ActivityDetailSerializer(serializers.ModelSerializer):
    host = HostSerializer(read_only=True)
    member_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)
    recent_members = serializers.SerializerMethodField()
    has_joined = serializers.SerializerMethodField()

    def get_recent_members(self, obj):
        # Return up to 4 members for the stacked avatar display
        recent = obj.members.select_related('user').order_by('joined_at')[:4]
        return MemberSerializer(recent, many=True).data

    def get_has_joined(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.members.filter(user=request.user).exists()
        return False

    class Meta:
        model = Activity
        fields = [
            'id', 'title', 'description', 'image_url',
            'location', 'meeting_point',
            'date', 'time',
            'is_women_only', 'is_accessible', 'is_free',
            'member_count', 'max_members', 'is_full',
            'host', 'recent_members', 'has_joined',
            'created_at',
        ]


# ── Create activity ───────────────────────────────────────────────────────────

class CreateActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Activity
        fields = [
            'title', 'description',
            'location', 'meeting_point',
            'date', 'time',
            'is_women_only', 'is_accessible', 'is_free',
            'max_members', 'image_url',
        ]

    def create(self, validated_data):
        # Host is always the authenticated user — never let the client set it.
        validated_data['host'] = self.context['request'].user
        return super().create(validated_data)


# ── Notifications ─────────────────────────────────────────────────────────────

class NotificationSerializer(serializers.ModelSerializer):
    activity_id = serializers.IntegerField(source='activity.id', allow_null=True, read_only=True)
    activity_title = serializers.CharField(source='activity.title', allow_null=True, read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'body',
            'activity_id', 'activity_title',
            'is_read', 'created_at',
        ]


# ── People match (home screen) ────────────────────────────────────────────────

class PeopleMatchSerializer(serializers.ModelSerializer):
    """Compact user card for 'People You Might Vibe With'."""
    interests = serializers.SerializerMethodField()

    def get_interests(self, obj):
        return list(obj.interests.values_list('name', flat=True))

    class Meta:
        model = User
        fields = ['id', 'full_name', 'gender', 'interests']
