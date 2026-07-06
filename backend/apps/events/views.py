from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model
from django.db.models import Q

from .models import Activity, ActivityMember, Notification
from .serializers import (
    ActivityCardSerializer,
    ActivityDetailSerializer,
    CreateActivitySerializer,
    NotificationSerializer,
    PeopleMatchSerializer,
)

User = get_user_model()


# ── Helpers ──────────────────────────────────────────────────────────────────

def _build_match_percents(user, activities):
    """
    Calculates a simple interest-overlap match percentage between the
    authenticated user and each activity's host.
    Formula: (shared interests / user's total interests) * 100
    Capped at 100. Falls back to 0 if user has no interests.
    """
    user_interests = set(user.interests.values_list('name', flat=True))
    if not user_interests:
        return {}

    result = {}
    for activity in activities:
        host_interests = set(
            activity.host.interests.values_list('name', flat=True)
        )
        shared = user_interests & host_interests
        pct = min(100, round(len(shared) / len(user_interests) * 100))
        result[activity.id] = pct if pct > 0 else None
    return result


# ── Home feed ─────────────────────────────────────────────────────────────────

class HomeFeedView(APIView):
    """
    GET /api/events/home/

    Returns:
      - activities: upcoming activities (nearest 10)
      - people: other users to vibe with (all others, limited to 10)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # ── Activities: upcoming, exclude the user's own hosted ones ─────────
        activities = (
            Activity.objects
            .select_related('host')
            .prefetch_related('members', 'host__interests')
            .order_by('date', 'time')[:20]
        )

        match_percents = _build_match_percents(user, activities)

        activity_data = ActivityCardSerializer(
            activities,
            many=True,
            context={
                'request': request,
                'match_percents': match_percents,
            },
        ).data

        # ── People: all other onboarded users ────────────────────────────────
        people = (
            User.objects
            .filter(is_onboarding_complete=True)
            .exclude(id=user.id)
            .prefetch_related('interests')
            [:10]
        )

        people_data = PeopleMatchSerializer(people, many=True).data

        # ── Notification unread count (for the bell badge) ───────────────────
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
    GET  /api/events/activities/         — full list
    POST /api/events/activities/         — create new activity
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        activities = (
            Activity.objects
            .select_related('host')
            .prefetch_related('members', 'host__interests')
            .order_by('date', 'time')
        )
        match_percents = _build_match_percents(request.user, activities)
        serializer = ActivityCardSerializer(
            activities, many=True,
            context={'request': request, 'match_percents': match_percents},
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
    """
    GET /api/events/activities/<id>/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            activity = (
                Activity.objects
                .select_related('host')
                .prefetch_related('members__user', 'host__interests')
                .get(pk=pk)
            )
        except Activity.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = ActivityDetailSerializer(activity, context={'request': request})
        return Response(serializer.data)


# ── Join / Leave activity ─────────────────────────────────────────────────────

class JoinActivityView(APIView):
    """
    POST   /api/events/activities/<id>/join/   — join
    DELETE /api/events/activities/<id>/join/   — leave
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
            activity=activity,
            user=request.user,
        )

        if not created:
            return Response(
                {'detail': 'You have already joined this activity.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Notify the host that someone joined
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
    """
    GET  /api/events/notifications/         — list all notifications
    POST /api/events/notifications/read/    — mark all as read
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(recipient=request.user)
        return Response(NotificationSerializer(notifications, many=True).data)


class MarkNotificationsReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(
            recipient=request.user, is_read=False
        ).update(is_read=True)
        return Response({'detail': 'All notifications marked as read.'})


# ── Search ────────────────────────────────────────────────────────────────────

class SearchView(APIView):
    """
    GET /api/events/search/?q=<query>

    Searches across activities (title, location) and users (full_name).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        q = request.query_params.get('q', '').strip()
        if not q:
            return Response({'activities': [], 'people': []})

        activities = (
            Activity.objects
            .filter(
                Q(title__icontains=q) | Q(location__icontains=q)
            )
            .select_related('host')
            .prefetch_related('members')
            [:20]
        )

        people = (
            User.objects
            .filter(
                Q(full_name__icontains=q),
                is_onboarding_complete=True,
            )
            .exclude(id=request.user.id)
            .prefetch_related('interests')
            [:10]
        )

        return Response({
            'activities': ActivityCardSerializer(
                activities, many=True, context={'request': request}
            ).data,
            'people': PeopleMatchSerializer(people, many=True).data,
        })
