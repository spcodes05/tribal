from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.users.serializer_mixins import ProfileImageMixin
from .models import Activity, ActivityMember, Notification

User = get_user_model()


# ── Nested host summary used inside ActivitySerializer ───────────────────────

class HostSerializer(ProfileImageMixin, serializers.ModelSerializer):
    profile_image = serializers.SerializerMethodField()

    def get_profile_image(self, obj):
        return self.build_profile_image_url(obj)

    class Meta:
        model = User
        fields = ['id', 'full_name', 'is_email_verified', 'profile_image']


# ── Member summary (stacked avatars on card) ─────────────────────────────────

class MemberSerializer(ProfileImageMixin, serializers.ModelSerializer):
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    profile_image = serializers.SerializerMethodField()

    def get_profile_image(self, obj):
        return self.build_profile_image_url(obj.user)

    class Meta:
        model = ActivityMember
        fields = ['user_id', 'full_name', 'profile_image', 'joined_at']


# ── Activity list card (compact, for home screen) ─────────────────────────────

class ActivityCardSerializer(serializers.ModelSerializer):
    host_name = serializers.CharField(source='host.full_name', read_only=True)
    tags = serializers.SerializerMethodField()
    recommendation_score = serializers.SerializerMethodField()
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

    def get_tags(self, obj):
        return list(obj.tags.values_list("name", flat=True))


    def get_recommendation_score(self, obj):
        scores = self.context.get("recommendation_scores", {})
        return round(scores.get(obj.id, 0), 3)

    class Meta:
        model = Activity
        fields = [
         "id",
         "title",
         "image_url",

         "location",
         "latitude",
        "longitude",

         "date",
         "time",

         "tags",

         "is_women_only",
         "is_accessible",
         "is_free",

         "member_count",
         "max_members",
         "is_full",

         "host_name",

         "distance_km",
         "match_percent",
         "recommendation_score",
    ]


# ── Activity detail (full, for activity detail screen) ────────────────────────

class ActivityDetailSerializer(serializers.ModelSerializer):
    host = HostSerializer(read_only=True)
    member_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)
    recent_members = serializers.SerializerMethodField()
    has_joined = serializers.SerializerMethodField()
    tags = serializers.SerializerMethodField()

    def get_tags(self, obj):
        return list(obj.tags.values_list("name", flat=True))

    def get_recent_members(self, obj):
        # Return up to 4 members for the stacked avatar display
        recent = obj.members.select_related('user').order_by('joined_at')[:4]
        return MemberSerializer(recent, many=True, context=self.context).data

    def get_has_joined(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.members.filter(user=request.user).exists()
        return False

    class Meta:
        model = Activity
        fields = [
        "id",
        "title",
        "description",
        "image_url",

        "location",
        "meeting_point",

        "latitude",
        "longitude",

        "date",
        "time",

        "tags",

        "is_women_only",
        "is_accessible",
        "is_free",

        "member_count",
        "max_members",
        "is_full",

        "host",
        "recent_members",
        "has_joined",

        "created_at",
        ]


# ── Create activity ───────────────────────────────────────────────────────────

class CreateActivitySerializer(serializers.ModelSerializer):
    # Accept a list of Interest IDs to set as activity tags.
    # Write-only — not returned in the response (ActivityDetailSerializer
    # returns the full tags list).
    tag_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
        default=list,
    )

    class Meta:
        model = Activity
        fields = [
            'title', 'description',
            'location', 'meeting_point',
            'latitude', 'longitude',
            'date', 'time',
            'is_women_only', 'is_accessible', 'is_free',
            'max_members', 'image_url',
            'tag_ids',
        ]

    def create(self, validated_data):
        tag_ids = validated_data.pop('tag_ids', [])
        validated_data['host'] = self.context['request'].user
        activity = super().create(validated_data)
        if tag_ids:
            from apps.users.models import Interest
            activity.tags.set(Interest.objects.filter(id__in=tag_ids))
        return activity


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

class PeopleMatchSerializer(ProfileImageMixin, serializers.ModelSerializer):
    """Compact user card for 'People You Might Vibe With'."""
    interests = serializers.SerializerMethodField()
    match_percent = serializers.SerializerMethodField()
    profile_image = serializers.SerializerMethodField()

    def get_interests(self, obj):
        return list(obj.interests.values_list('name', flat=True))

    def get_match_percent(self, obj):
        return self.context.get('match_percents', {}).get(obj.id)

    def get_profile_image(self, obj):
        return self.build_profile_image_url(obj)

    class Meta:
        model = User
        fields = ['id', 'full_name', 'gender', 'interests', 'match_percent', 'profile_image']
