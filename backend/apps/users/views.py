from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes



from .serializers import (
    RegisterSerializer,
    VerifyEmailSerializer,
    GenderSerializer,
    SaveInterestsSerializer,
    UserDetailSerializer,
)
from .emails import send_verification_email
from .models import Interest

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
            try:
                send_verification_email(user)
            except Exception as e:
                # Log the error but don't fail registration.
                # The user can request a new verification email later.
                print(f"[WARNING] Failed to send verification email: {e}")

            tokens = get_tokens_for_user(user)

            return Response(
                {
                    "message": "Registration successful. Please check your email to verify your account.",
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

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


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
    POST /api/users/interests/
    Body: { "interests": ["Hiking", "Music", "Gaming"] }

    Replaces the user's current interests with the submitted list.
    (Not additive — submitting ["Hiking"] removes all others.)

    Requires authentication and verified email.
    """
    permission_classes = [IsAuthenticated]

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

    def get(self, request):
        """
        GET /api/users/interests/
        Returns the full list of available predefined interests.
        Useful so the frontend can populate the interests selection screen.
        """
        interests = Interest.objects.all().order_by("name")
        data = [{"id": i.id, "name": i.name} for i in interests]
        return Response({"interests": data}, status=status.HTTP_200_OK)


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
        serializer = UserDetailSerializer(request.user)
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