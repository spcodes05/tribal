from django.utils import timezone
from datetime import timedelta
from django.db.models import Q
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q
from django.shortcuts import get_object_or_404

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.generics import ListAPIView
from rest_framework_simplejwt.tokens import RefreshToken

from django.contrib.auth import get_user_model

from .serializers import (
    RegisterSerializer,
    VerifyEmailSerializer,
    ResendVerificationSerializer,
    GenderSerializer,
    SaveInterestsSerializer,
    UserDetailSerializer,
    UserSearchSerializer,
    PublicUserProfileSerializer,
    ProfileUpdateSerializer,
    ReportUserSerializer,
)

from .emails import send_verification_email
from .models import (
    CustomUser,
    Interest,
    UserBlock,
    UserReport,
)

import logging

logger = logging.getLogger(__name__)

User = get_user_model()


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


# ─────────────────────────────────────────────
# REGISTER
# ─────────────────────────────────────────────

class RegisterView(APIView):
    """
    POST /api/users/register/

    Creates account, sends verification email, returns tokens.
    Tokens are returned but full app access is gated behind email verification.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            # Send the verification email.
            # In development this prints to the terminal.
            email_sent = True
            try:
                send_verification_email(user)
            except Exception:
                email_sent = False
                logger.warning(
                    "Failed to send verification email to user_id=%s", user.id,
                    exc_info=True,
                )

            tokens = get_tokens_for_user(user)

            message = (
                "Registration successful. Please check your email to verify your account."
                if email_sent
                else "Registration successful, but we couldn't send the verification "
                     "email right now. Use 'Resend verification email' to try again."
            )

            return Response(
                {
                    "message": message,
                    "email_sent": email_sent,
                    "user": {
                        "id": user.id,
                        "full_name": user.full_name,
                        "email": user.email,
                        "is_email_verified": user.is_email_verified,
                    },
                    "tokens": tokens,
                },
                status=status.HTTP_201_CREATED,
            )


# ─────────────────────────────────────────────
# EMAIL VERIFICATION
# ─────────────────────────────────────────────

class VerifyEmailView(APIView):
    """
    POST /api/users/verify-email/
    Body: { "token": "<uuid>" }

    The frontend extracts the token from the URL query parameter
    and sends it here. No authentication required — the token itself
    is the proof of identity.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        token = serializer.validated_data["token"]

        try:
            user = User.objects.get(verification_token=token)
        except User.DoesNotExist:
            return Response(
                {"detail": "Invalid verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check if already verified (idempotent — not an error).
        if user.is_email_verified:
            return Response(
                {"detail": "Email already verified."},
                status=status.HTTP_200_OK,
            )

        # Check token expiry.
        if timezone.now() > user.verification_token_expiry:
            return Response(
                {
                    "detail": "Verification token has expired. Please request a new one.",
                    "code": "token_expired",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # All checks passed — verify the email.
        user.verify_email()

        return Response(
            {
                "message": "Email verified successfully. You can now continue onboarding.",
                "is_email_verified": True,
            },
            status=status.HTTP_200_OK,
        )


# ─────────────────────────────────────────────
# RESEND VERIFICATION
# ─────────────────────────────────────────────

class ResendVerificationView(APIView):
    """
    POST /api/users/resend-verification/
    Body: { "email": "user@example.com" }

    Generates a fresh verification token (invalidating the old one) and
    re-sends the verification email. This is what closes the loop that
    was previously missing: without it, a user whose original email
    never arrived (or whose token expired) had no way to get a new one.

    Always returns a generic success message, whether or not the email
    exists, so this endpoint can't be used to enumerate registered users.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ResendVerificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data["email"].lower().strip()
        generic_response = Response(
            {"message": "If that email is registered, a new verification link has been sent."},
            status=status.HTTP_200_OK,
        )

        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            return generic_response

        if user.is_email_verified:
            return Response(
                {"detail": "Email already verified."},
                status=status.HTTP_200_OK,
            )

        user.generate_verification_token()
        try:
            send_verification_email(user)
        except Exception:
            logger.warning(
                "Failed to resend verification email to user_id=%s", user.id,
                exc_info=True,
            )

        return generic_response


# ─────────────────────────────────────────────
# LOGIN
# ─────────────────────────────────────────────

class LoginView(APIView):
    """
    POST /api/users/login/
    Body: { "email": "...", "password": "..." }

    Blocks login if email is not verified.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email", "").lower().strip()
        password = request.data.get("password", "")

        if not email or not password:
            return Response(
                {"detail": "Email and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            # Generic message to prevent user enumeration attacks.
            return Response(
                {"detail": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.check_password(password):
            return Response(
                {"detail": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.is_active:
            return Response(
                {"detail": "This account has been deactivated."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # ── EMAIL VERIFICATION GATE ──
        if not user.is_email_verified:
            return Response(
                {
                    "detail": "Please verify your email before logging in.",
                    "code": "email_not_verified",
                    # The frontend can use this 'code' field to show
                    # a "Resend verification email" button.
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        tokens = get_tokens_for_user(user)

        return Response(
            {
                "user": {
                    "id": user.id,
                    "full_name": user.full_name,
                    "email": user.email,
                    "is_email_verified": user.is_email_verified,
                    "is_onboarding_complete": user.is_onboarding_complete,
                },
                "tokens": tokens,
            },
            status=status.HTTP_200_OK,
        )


# ─────────────────────────────────────────────
# GENDER
# ─────────────────────────────────────────────

class GenderView(APIView):
    """
    POST /api/users/gender/
    Body: { "gender": "male" }

    Requires authentication (JWT token in Authorization header).
    Requires email to be verified first.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Gate: email must be verified before proceeding with onboarding.
        if not request.user.is_email_verified:
            return Response(
                {"detail": "Please verify your email first."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = GenderSerializer(
            instance=request.user,   # The user record to update
            data=request.data,
            partial=True,
            # partial=True means we only update the fields provided,
            # leaving all other fields unchanged.
        )

        if serializer.is_valid():
            serializer.save()

            # Recalculate onboarding completion status.
            request.user.check_onboarding_complete()

            return Response(
                {
                    "message": "Gender saved successfully.",
                    "gender": request.user.gender,
                    "is_onboarding_complete": request.user.is_onboarding_complete,
                },
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─────────────────────────────────────────────
# INTERESTS
# ─────────────────────────────────────────────

class InterestsView(APIView):
    """
    GET  /api/users/interests/   — returns all predefined interests with IDs
    POST /api/users/interests/   — saves user's selected interests
    Body: { "interests": ["Hiking", "Music", "Gaming"] }

    Replaces the user's current interests with the submitted list.
    (Not additive — submitting ["Hiking"] removes all others.)

    Requires authentication and verified email.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Return all available interests as {"interests": [{id, name}, ...]}
        for picker UIs. Wrapped (not a bare list) — this matches what
        OnboardingService.fetchAvailableInterests() and
        RoommateService._resolveInterestIds() already expect on the
        frontend, so both keep working unchanged.
        """
        from apps.users.models import Interest
        interests = Interest.objects.all().order_by('name')
        return Response({'interests': [{'id': i.id, 'name': i.name} for i in interests]})

    def post(self, request):
        if not request.user.is_email_verified:
            return Response(
                {"detail": "Please verify your email first."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = SaveInterestsSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        interest_names = serializer.validated_data["interests"]

        # Fetch the Interest objects matching the submitted names.
        # We know they're valid because the serializer already validated them.
        interest_objects = Interest.objects.filter(name__in=interest_names)

        # .set() replaces the current ManyToMany relationship entirely.
        # This is cleaner than .clear() + .add() because it's one query
        # and handles duplicates automatically.
        request.user.interests.set(interest_objects)

        # Recalculate onboarding completion status.
        request.user.check_onboarding_complete()

        return Response(
            {
                "message": "Interests saved successfully.",
                "interests": list(interest_objects.values_list("name", flat=True)),
                "is_onboarding_complete": request.user.is_onboarding_complete,
            },
            status=status.HTTP_200_OK,
        )


# ─────────────────────────────────────────────
# ME
# ─────────────────────────────────────────────

class MeView(APIView):
    """
    GET /api/users/me/
    Returns the full profile of the authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserDetailSerializer(request.user,context={"request": request},)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @api_view(["POST"])
    def set_gender(request):
        user = request.user
        gender = request.data.get("gender")

        if not gender:
           return Response({"error": "Gender is required"}, status=400)

        user.gender = gender
        user.save()

        user.update_onboarding_status()

        return Response({"message": "Gender updated"})
    
    @api_view(["POST"])
    def set_interests(request):
         user = request.user
         interests = request.data.get("interests")  # list of IDs

         if not interests:
            return Response({"error": "Interests are required"}, status=400)

         user.interests.set(interests)
         user.update_onboarding_status()

         return Response({"message": "Interests updated"})
    



@api_view(["POST"])
@permission_classes([IsAuthenticated])
def set_gender(request):
    user = request.user
    user.gender = request.data.get("gender")
    user.save()

    return Response({"message": "gender updated"})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def set_interests(request):
    user = request.user
    interests = request.data.get("interests")

    user.interests.set(interests)
    user.save()

    return Response({"message": "interests updated"})

class LocationView(APIView):
    """
    POST /api/users/location/

    Saves the authenticated user's latitude and longitude.
    Called from the Flutter app whenever the user grants location permission
    or manually sets their area.

    Request body:
        { "latitude": 27.7172, "longitude": 85.3240 }

    Response:
        { "message": "Location updated.", "latitude": 27.7172, "longitude": 85.3240 }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        lat = request.data.get('latitude')
        lon = request.data.get('longitude')

        if lat is None or lon is None:
            return Response(
                {'detail': 'Both latitude and longitude are required.'},
                status=400,
            )

        try:
            lat = float(lat)
            lon = float(lon)
        except (TypeError, ValueError):
            return Response(
                {'detail': 'latitude and longitude must be valid numbers.'},
                status=400,
            )

        if not (-90 <= lat <= 90) or not (-180 <= lon <= 180):
            return Response(
                {'detail': 'Invalid coordinates.'},
                status=400,
            )

        request.user.latitude = lat
        request.user.longitude = lon
        request.user.save(update_fields=['latitude', 'longitude'])

        return Response({
            'message': 'Location updated.',
            'latitude': lat,
            'longitude': lon,
        })

# ─────────────────────────────────────────────
# PROFILE IMAGE UPLOAD (Tribe Status — tap avatar)
# ─────────────────────────────────────────────

class ProfileImageUploadView(APIView):
    """
    POST   /api/users/me/profile-image/   multipart field name "image"
    DELETE /api/users/me/profile-image/   removes the current photo
    """
    permission_classes = [IsAuthenticated]

    ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}
    MAX_SIZE_BYTES = 8 * 1024 * 1024  # 8MB

    def post(self, request):
        image_file = request.FILES.get("image")
        if not image_file:
            return Response({"detail": "No image file provided."}, status=status.HTTP_400_BAD_REQUEST)

        if image_file.content_type not in self.ALLOWED_CONTENT_TYPES:
            return Response(
                {"detail": "Please upload a JPEG, PNG, or WEBP image."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if image_file.size > self.MAX_SIZE_BYTES:
            return Response(
                {"detail": "Image must be smaller than 8MB."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Capture the old file's storage path (not the FieldFile object)
        # BEFORE reassigning, then delete it AFTER the new file is safely
        # saved. Every upload gets a fresh UUID filename (see
        # apps.users.models.profile_image_upload_path), so this ordering
        # can never result in the new file colliding with the old URL.
        old_name = request.user.profile_image.name if request.user.profile_image else None

        request.user.profile_image = image_file
        request.user.save(update_fields=["profile_image"])

        if old_name:
            request.user.profile_image.storage.delete(old_name)

        return Response(PublicUserProfileSerializer(request.user, context={"request": request}).data)

    def delete(self, request):
        old_name = request.user.profile_image.name if request.user.profile_image else None
        request.user.profile_image = ""
        request.user.save(update_fields=["profile_image"])
        if old_name:
            request.user.profile_image.storage.delete(old_name)
        return Response(PublicUserProfileSerializer(request.user, context={"request": request}).data)

# ─────────────────────────────────────────────
# MUTUAL ACTIVITIES
# ─────────────────────────────────────────────

class MutualActivitiesView(APIView):
    """
    GET /api/users/<user_id>/mutual-activities/

    Activities that BOTH the requesting user and <user_id> have joined.
    Reuses ActivityCardSerializer (same shape already used by the Home
    feed and Tribe Status's upcoming activity), so the frontend needed
    no new model at all.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        from apps.events.models import Activity, ActivityMember
        from apps.events.serializers import ActivityCardSerializer
        from apps.roommate.models import RoommateMatch

        target = get_object_or_404(User, pk=user_id, is_active=True)

        if UserBlock.objects.filter(blocker=target, blocked=request.user).exists():
            return Response({"detail": "This profile is not available."}, status=status.HTTP_404_NOT_FOUND)

        my_activity_ids = set(
            ActivityMember.objects.filter(user=request.user).values_list("activity_id", flat=True)
        )
        their_activity_ids = set(
            ActivityMember.objects.filter(user=target).values_list("activity_id", flat=True)
        )
        mutual_ids = my_activity_ids & their_activity_ids

        activities = (
            Activity.objects.filter(id__in=mutual_ids)
            .select_related("host")
            .order_by("-date", "-time")
        )

        # Real roommate compatibility if it exists — never fabricated.
        match = (
            RoommateMatch.objects.filter(
                Q(user=request.user, matched_user=target) | Q(user=target, matched_user=request.user)
            ).order_by("-updated_at").first()
        )
        compatibility = round(float(match.compatibility_score)) if match else None
        match_percents = {a.id: compatibility for a in activities} if compatibility is not None else {}

        serializer = ActivityCardSerializer(
            activities, many=True,
            context={"request": request, "match_percents": match_percents},
        )
        return Response({"activities": serializer.data})


class UserSearchView(ListAPIView):
    serializer_class = UserSearchSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        query = self.request.query_params.get("query", "")

        if not query:
            return CustomUser.objects.none()

        return CustomUser.objects.filter(
            Q(full_name__icontains=query) |
            Q(email__icontains=query)
        ).exclude(
            id=self.request.user.id
        )



# ─────────────────────────────────────────────
# TRIBE STATUS (own profile: stats + upcoming activity + timeline + achievements)
# ─────────────────────────────────────────────
 
class TribeStatusView(APIView):
    """
    GET /api/users/me/tribe-status/
 
    Single aggregate endpoint (same pattern as events.HomeFeedView) so the
    "Your Tribe Status" screen renders in one round trip.
 
    Every number returned here is computed from real, existing data:
      - activities_joined / events_hosted -> apps.events
      - roommate_matches                  -> apps.roommate
      - people_met / chat_streak          -> apps.chat
 
    No "Friends Made" or "Communities Joined" stat is returned — Tribal has
    no friendship or community model, so those numbers can't be computed
    honestly. Achievements are derived thresholds on the same real counts.
    """
    permission_classes = [IsAuthenticated]
 
    def get(self, request):
        from apps.events.models import Activity, ActivityMember
        from apps.events.serializers import ActivityCardSerializer
        from apps.roommate.models import RoommateMatch
        from apps.chat.models import Chat, Message
 
        user = request.user
 
        # ── Stats ──────────────────────────────────────────────────────────
        activities_joined = ActivityMember.objects.filter(user=user).count()
        events_hosted = Activity.objects.filter(host=user).count()
        roommate_matches = RoommateMatch.objects.filter(user=user).count()
 
        chat_partner_ids = set()
        for chat in Chat.for_user(user).select_related("participant_one", "participant_two"):
            try:
                chat_partner_ids.add(chat.get_other_participant(user).id)
            except ValueError:
                continue
        roommate_partner_ids = set(
            RoommateMatch.objects.filter(user=user).values_list("matched_user_id", flat=True)
        )
        people_met = len(chat_partner_ids | roommate_partner_ids)
 
        chat_streak = self._compute_chat_streak(user, Message)
 
        stats = {
            "activities_joined": activities_joined,
            "events_hosted": events_hosted,
            "roommate_matches": roommate_matches,
            "people_met": people_met,
            "chat_streak": chat_streak,
        }
 
        # ── Upcoming activity (soonest one the user has joined, in the future) ──
        upcoming_member = (
            ActivityMember.objects
            .filter(user=user, activity__date__gte=timezone.localdate())
            .select_related("activity", "activity__host")
            .order_by("activity__date", "activity__time")
            .first()
        )
        upcoming_activity = None
        if upcoming_member is not None:
            upcoming_activity = ActivityCardSerializer(
                upcoming_member.activity, context={"request": request}
            ).data
 
        # ── Recent timeline (joined / hosted / matched, newest first) ───────
        timeline = []
        for m in (
            ActivityMember.objects.filter(user=user)
            .select_related("activity")
            .order_by("-joined_at")[:5]
        ):
            timeline.append({
                "type": "joined_activity",
                "title": f"Joined {m.activity.title}",
                "date": m.joined_at.isoformat(),
                "location": m.activity.location,
                "people_count": m.activity.member_count,
                "image_url": m.activity.image_url or None,
            })
        for a in Activity.objects.filter(host=user).order_by("-created_at")[:5]:
            timeline.append({
                "type": "hosted_activity",
                "title": f"Hosted {a.title}",
                "date": a.created_at.isoformat(),
                "location": a.location,
                "people_count": a.member_count,
                "image_url": a.image_url or None,
            })
        for rm in (
            RoommateMatch.objects.filter(user=user)
            .select_related("matched_user")
            .order_by("-created_at")[:5]
        ):
            timeline.append({
                "type": "roommate_match",
                "title": f"Matched with {rm.matched_user.full_name}",
                "date": rm.created_at.isoformat(),
                "location": None,
                "people_count": None,
                "image_url": None,
            })
        timeline.sort(key=lambda e: e["date"], reverse=True)
        timeline = timeline[:8]
 
        # ── Achievements (derived thresholds on real counts) ────────────────
        achievements = [
            {"key": "explorer", "label": "Explorer", "description": "Joined 5+ activities", "earned": activities_joined >= 5},
            {"key": "host", "label": "Host", "description": "Hosted your first activity", "earned": events_hosted >= 1},
            {"key": "roommate_ready", "label": "Roommate Ready", "description": "Found a roommate match", "earned": roommate_matches >= 1},
            {"key": "conversationalist", "label": "Conversationalist", "description": "3-day chat streak", "earned": chat_streak >= 3},
            {"key": "social_butterfly", "label": "Social Butterfly", "description": "Met 5+ people", "earned": people_met >= 5},
        ]
 
        return Response({
            "profile": PublicUserProfileSerializer(user, context={"request": request}).data,
            "stats": stats,
            "upcoming_activity": upcoming_activity,
            "recent_timeline": timeline,
            "achievements": achievements,
        })
 
    @staticmethod
    def _compute_chat_streak(user, Message):
        dates = set(
            Message.objects.filter(sender=user).values_list("timestamp", flat=True)
        )
        date_set = {ts.date() for ts in dates}
        if not date_set:
            return 0
 
        today = timezone.localdate()
        cursor = today
        if cursor not in date_set:
            cursor = cursor - timedelta(days=1)
            if cursor not in date_set:
                return 0
 
        streak = 0
        while cursor in date_set:
            streak += 1
            cursor -= timedelta(days=1)
        return streak
 
 
# ─────────────────────────────────────────────
# PROFILE UPDATE (Settings screen)
# ─────────────────────────────────────────────
 
class UpdateProfileView(APIView):
    """PATCH /api/users/me/update/"""
    permission_classes = [IsAuthenticated]
 
    def patch(self, request):
        serializer = ProfileUpdateSerializer(
            instance=request.user, data=request.data, partial=True,
        )
        if serializer.is_valid():
            serializer.save()
            return Response(PublicUserProfileSerializer(request.user, context={"request": request}).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
 
 
# ─────────────────────────────────────────────
# OTHER USER PROFILE
# ─────────────────────────────────────────────
 
class PublicProfileView(APIView):
    """
    GET /api/users/<user_id>/profile/
 
    Returns another user's public profile plus context relative to the
    requesting user: mutual interests, roommate compatibility (only if a
    real RoommateMatch row exists between the two — never fabricated),
    and their public tribe activity.
    """
    permission_classes = [IsAuthenticated]
 
    def get(self, request, user_id):
        from apps.roommate.models import RoommateMatch
        from apps.events.models import Activity, ActivityMember
 
        target = get_object_or_404(CustomUser, pk=user_id, is_active=True)
    
 
        # Hide profiles that have blocked the requester.
        if UserBlock.objects.filter(blocker=target, blocked=request.user).exists():
            return Response({"detail": "This profile is not available."}, status=status.HTTP_404_NOT_FOUND)
 
        my_interests = set(request.user.interests.values_list("name", flat=True))
        their_interests = set(target.interests.values_list("name", flat=True))
        mutual_interests = sorted(my_interests & their_interests)
 
        # Only use a real, already-computed roommate score. Never invent one.
        match = (
            RoommateMatch.objects.filter(
                Q(user=request.user, matched_user=target) | Q(user=target, matched_user=request.user)
            ).order_by("-updated_at").first()
        )
        compatibility_percent = round(float(match.compatibility_score)) if match else None
 
        activities_joined = ActivityMember.objects.filter(user=target).count()
        recent_public_events = [
            {"title": m.activity.title, "date": m.activity.date.isoformat(), "location": m.activity.location}
            for m in (
                ActivityMember.objects.filter(user=target)
                .select_related("activity")
                .order_by("-joined_at")[:5]
            )
        ]
 
        is_blocked_by_me = UserBlock.objects.filter(blocker=request.user, blocked=target).exists()
 
        return Response({
            "profile": PublicUserProfileSerializer(target, context={"request": request}).data,
            "mutual_interests": mutual_interests,
            "compatibility_percent": compatibility_percent,
            "tribe_activity": {
                "activities_joined": activities_joined,
                "recent_public_events": recent_public_events,
            },
            "is_blocked_by_me": is_blocked_by_me,
        })
 
 
# ─────────────────────────────────────────────
# BLOCK / REPORT
# ─────────────────────────────────────────────
 
class BlockUserView(APIView):
    """
    POST   /api/users/<user_id>/block/   — block
    DELETE /api/users/<user_id>/block/   — unblock
    """
    permission_classes = [IsAuthenticated]
 
    def post(self, request, user_id):
        target = get_object_or_404(CustomUser, pk=user_id)
        if target.id == request.user.id:
            return Response({"detail": "You cannot block yourself."}, status=status.HTTP_400_BAD_REQUEST)
        UserBlock.objects.get_or_create(blocker=request.user, blocked=target)
        return Response({"detail": "User blocked.", "is_blocked": True})
 
    def delete(self, request, user_id):
        target = get_object_or_404(CustomUser, pk=user_id)
        UserBlock.objects.filter(blocker=request.user, blocked=target).delete()
        return Response({"detail": "User unblocked.", "is_blocked": False})
 
 
class ReportUserView(APIView):
    """POST /api/users/<user_id>/report/  Body: { "reason": "...", "details": "..." }"""
    permission_classes = [IsAuthenticated]
 
    def post(self, request, user_id):
        target = get_object_or_404(CustomUser, pk=user_id)
        serializer = ReportUserSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
 
        UserReport.objects.create(
            reporter=request.user,
            reported_user=target,
            reason=serializer.validated_data["reason"],
            details=serializer.validated_data.get("details", ""),
        )
        return Response({"detail": "Report submitted. Our team will review it."}, status=status.HTTP_201_CREATED)