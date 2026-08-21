from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model

from .models import Activity, ActivityMember, Notification
from .recommendations import rank_activities, rank_people, score_activity
from .utils import filter_active, delete_expired_activities
from .serializers import (
    ActivityCardSerializer,
    ActivityDetailSerializer,
    CreateActivitySerializer,
    NotificationSerializer,
    PeopleMatchSerializer,
)

User = get_user_model()


# ── Home feed ─────────────────────────────────────────────────────────────────

class HomeFeedView(APIView):
    """
    GET /api/events/home/

    Returns activities and people ranked by the hybrid recommendation engine:

    Activities:  Score = 0.70 × TagSimilarity(Jaccard)
                       + 0.20 × PopularityScore
                       + 0.10 × LocationScore(Haversine)

    People:      Score = 0.50 × InterestSimilarity(Jaccard)
                       + 0.30 × ActivityOverlap(Jaccard)
                       + 0.20 × LocationScore(Haversine)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # Opportunistic cleanup: this is the most frequently hit endpoint,
        # so piggy-back the actual delete here. Cheap (single DELETE query)
        # and means expired activities get purged without needing a task
        # queue set up. The management command below handles it properly
        # for deployments that do have cron/scheduling available.
        delete_expired_activities()

        # ── Rank activities ──────────────────────────────────────────────────
        activities_qs = filter_active(
            Activity.objects
            .select_related('host')
            .prefetch_related('members__user__interests', 'tags', 'host__interests')
        )

        ranked_activities = rank_activities(user, activities_qs)

        # Inject match_percent into serializer context keyed by activity id
        match_percents = {
            r["activity"].id: r["match_percent"]
            for r in ranked_activities
        }

        recommendation_scores = {
            r["activity"].id: r["final_score"]
            for r in ranked_activities
        }
        # Preserve ranked order for serialization
        ordered_activities = [r['activity'] for r in ranked_activities]

        activity_data = ActivityCardSerializer(
            ordered_activities,
            many=True,
            context={
                'request': request,
                'match_percents': match_percents,
                'recommendation_scores': recommendation_scores,
            },
        ).data

        # ── Rank people ──────────────────────────────────────────────────────
        candidates = (
            User.objects
            .filter(is_onboarding_complete=True)
            .exclude(id=user.id)
            .prefetch_related('interests', 'joined_activities')
        )

        ranked_people = rank_people(user, candidates)

        # Inject match_percent into serializer context
        people_match_percents = {
            r['user'].id: r['match_percent']
            for r in ranked_people
        }
        ordered_people = [r['user'] for r in ranked_people[:10]]

        people_data = PeopleMatchSerializer(
            ordered_people,
            many=True,
            context={'request': request, 'match_percents': people_match_percents},
        ).data

        # ── Unread notification count (bell badge) ───────────────────────────
        unread_count = Notification.objects.filter(
            recipient=user, is_read=False
        ).count()

        return Response({
            'activities': activity_data,
            'people': people_data,
            'unread_notifications': unread_count,
        })


# ── Activity list + create ────────────────────────────────────────────────────

class ActivityListCreateView(APIView):
    """
    GET  /api/events/activities/  — full ranked list
    POST /api/events/activities/  — create new activity
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        activities_qs = filter_active(
            Activity.objects
            .select_related('host')
            .prefetch_related('members__user__interests', 'tags', 'host__interests')
        )
        ranked = rank_activities(request.user, activities_qs)
        match_percents = {
            r["activity"].id: r["match_percent"]
            for r in ranked
        }

        recommendation_scores = {
            r["activity"].id: r["final_score"]
            for r in ranked
        }
        ordered = [r['activity'] for r in ranked]

        serializer = ActivityCardSerializer(
            ordered, many=True,
            context={'request': request, 'match_percents': match_percents, "recommendation_scores": recommendation_scores,},
        )
        return Response(serializer.data)

    def post(self, request):
        serializer = CreateActivitySerializer(
            data=request.data,
            context={'request': request},
        )
        if serializer.is_valid():
            activity = serializer.save()
            return Response(
                ActivityDetailSerializer(activity, context={'request': request}).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Activity detail ───────────────────────────────────────────────────────────

class ActivityDetailView(APIView):
    """GET /api/events/activities/<id>/"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            activity = (
                Activity.objects
                .select_related('host')
                .prefetch_related(
                    'members__user__interests', 'tags', 'host__interests',
                )
                .get(pk=pk)
            )
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Reuse the same scoring function the home feed / list / search use,
        # so "match_percent" here is the real ActivityScore for this user,
        # not a placeholder.
        user = request.user
        u_interests = set(user.interests.values_list('name', flat=True))
        a_tags = set(activity.tags.values_list('name', flat=True))
        members_interests = [
            set(member.user.interests.values_list('name', flat=True))
            for member in activity.members.all()
        ]
        score = score_activity(
            user_interests=u_interests,
            user_lat=user.latitude,
            user_lon=user.longitude,
            activity_tags=a_tags,
            activity_member_count=activity.member_count,
            activity_max_members=activity.max_members,
            activity_lat=activity.latitude,
            activity_lon=activity.longitude,
            members_interests=members_interests,
        )
        match_percents = {activity.id: score['match_percent']}

        serializer = ActivityDetailSerializer(
            activity, context={'request': request, 'match_percents': match_percents},
        )
        return Response(serializer.data)

    def patch(self, request, pk):
        """PATCH /api/events/activities/<id>/ — edit an activity. Host only."""
        try:
            activity = Activity.objects.select_related('host').get(pk=pk)
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if activity.host_id != request.user.id:
            return Response(
                {'detail': 'Only the host can edit this activity.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CreateActivitySerializer(
            activity, data=request.data, partial=True,
            context={'request': request},
        )
        if serializer.is_valid():
            activity = serializer.save()
            return Response(
                ActivityDetailSerializer(activity, context={'request': request}).data,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        """DELETE /api/events/activities/<id>/ — delete an activity. Host only."""
        try:
            activity = Activity.objects.get(pk=pk)
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if activity.host_id != request.user.id:
            return Response(
                {'detail': 'Only the host can delete this activity.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        activity.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ── Join / Leave ──────────────────────────────────────────────────────────────

class JoinActivityView(APIView):
    """
    POST   /api/events/activities/<id>/join/  — join
    DELETE /api/events/activities/<id>/join/  — leave
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            activity = Activity.objects.get(pk=pk)
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if activity.is_full:
            return Response(
                {'detail': 'This activity is full.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        _, created = ActivityMember.objects.get_or_create(
            activity=activity, user=request.user,
        )

        if not created:
            return Response(
                {'detail': 'You have already joined this activity.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Notify host
        if activity.host != request.user:
            Notification.objects.create(
                recipient=activity.host,
                notification_type='join',
                title='Someone joined your activity!',
                body=f"{request.user.full_name} joined {activity.title}.",
                activity=activity,
            )

        return Response({
            'detail': 'Joined successfully.',
            'member_count': activity.member_count,
        }, status=status.HTTP_201_CREATED)

    def delete(self, request, pk):
        try:
            activity = Activity.objects.get(pk=pk)
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        deleted, _ = ActivityMember.objects.filter(
            activity=activity, user=request.user
        ).delete()

        if not deleted:
            return Response(
                {'detail': 'You have not joined this activity.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'detail': 'Left activity.',
            'member_count': activity.member_count,
        })


# ── Notifications ─────────────────────────────────────────────────────────────

class NotificationListView(APIView):
    """GET /api/events/notifications/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(recipient=request.user)
        return Response(NotificationSerializer(notifications, many=True).data)


class MarkNotificationsReadView(APIView):
    """POST /api/events/notifications/read/"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(
            recipient=request.user, is_read=False
        ).update(is_read=True)
        return Response({'detail': 'All notifications marked as read.'})


# ── Search ────────────────────────────────────────────────────────────────────

class SearchView(APIView):
    """GET /api/events/search/?q=<query>"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.db.models import Q

        q = request.query_params.get('q', '').strip()
        if not q:
            return Response({'activities': [], 'people': []})

        activities_qs = filter_active(
            Activity.objects
            .filter(Q(title__icontains=q) | Q(location__icontains=q))
            .select_related('host')
            .prefetch_related('members__user__interests', 'tags', 'host__interests')
        )
        ranked = rank_activities(request.user, activities_qs)
        match_percents = {
            r["activity"].id: r["match_percent"]
            for r in ranked
        }

        recommendation_scores = {
            r["activity"].id: r["final_score"]
            for r in ranked
        }
        ordered = [r['activity'] for r in ranked]

        people_qs = (
            User.objects
            .filter(Q(full_name__icontains=q), is_onboarding_complete=True)
            .exclude(id=request.user.id)
            .prefetch_related('interests', 'joined_activities')
        )
        ranked_people = rank_people(request.user, people_qs)
        people_match = {r['user'].id: r['match_percent'] for r in ranked_people}
        ordered_people = [r['user'] for r in ranked_people]

        return Response({
            'activities': ActivityCardSerializer(
                ordered, many=True,
                context={'request': request, 'match_percents': match_percents, "recommendation_scores": recommendation_scores},
            ).data,
            'people': PeopleMatchSerializer(
                ordered_people, many=True,
                context={'request': request, 'match_percents': people_match, "recommendation_scores": recommendation_scores},
            ).data,
        })


# ── Map pins ──────────────────────────────────────────────────────────────────

class ActivityMapView(APIView):
    """
    GET /api/events/activities/map/

    Returns lightweight pin data for all activities that have coordinates.
    Used by the Explore page map to place markers.

    Supports optional filtering:
      ?tag=Hiking          — filter by tag name
      ?is_free=true        — free activities only
      ?is_women_only=true  — women-only activities only
      ?this_weekend=true   — activities on the coming Saturday or Sunday
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.utils import timezone
        import datetime

        qs = filter_active(Activity.objects.filter(
            latitude__isnull=False,
            longitude__isnull=False,
        )).prefetch_related('tags', 'members')

        # ── Filters ───────────────────────────────────────────────────────
        tag = request.query_params.get('tag')
        if tag:
            qs = qs.filter(tags__name__iexact=tag)

        if request.query_params.get('is_free', '').lower() == 'true':
            qs = qs.filter(is_free=True)

        if request.query_params.get('is_women_only', '').lower() == 'true':
            qs = qs.filter(is_women_only=True)

        if request.query_params.get('this_weekend', '').lower() == 'true':
            today = timezone.now().date()
            days_to_saturday = (5 - today.weekday()) % 7
            saturday = today + datetime.timedelta(days=days_to_saturday)
            sunday = saturday + datetime.timedelta(days=1)
            qs = qs.filter(date__range=(saturday, sunday))

        pins = []
        for activity in qs:
            tags_list = list(activity.tags.values_list('name', flat=True))
            pins.append({
                'id': activity.id,
                'title': activity.title,
                'latitude': float(activity.latitude),
                'longitude': float(activity.longitude),
                'location': activity.location,
                'date': str(activity.date),
                'time': str(activity.time),
                'member_count': activity.member_count,
                'max_members': activity.max_members,
                'is_free': activity.is_free,
                'is_women_only': activity.is_women_only,
                'is_accessible': activity.is_accessible,
                'image_url': activity.image_url,
                'tags': tags_list,
                # Show the primary tag as the pin label (first tag or title)
                'pin_label': tags_list[0] if tags_list else activity.title,
            })

        return Response(pins)