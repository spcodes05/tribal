from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import RegisterSerializer, UserDetailSerializer


def get_tokens_for_user(user):
    """
    Manually generate JWT tokens for a given user.

    RefreshToken.for_user(user) creates a refresh token linked to that user.
    The access token is derived from the refresh token.

    We return both as strings so they can be included in the JSON response.
    """
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


class RegisterView(APIView):
    """
    POST /api/users/register/

    Creates a new user account.
    AllowAny: no authentication required (obviously — the user doesn't have an account yet).
    """

    permission_classes = [AllowAny]

    def post(self, request):
        # Pass the incoming request data to the serializer for validation.
        serializer = RegisterSerializer(data=request.data)

        if serializer.is_valid():
            # serializer.save() calls our create() method in RegisterSerializer,
            # which calls create_user() on the manager, which hashes the password.
            user = serializer.save()

            # Generate JWT tokens immediately after registration
            # so the user is logged in right after signing up.
            tokens = get_tokens_for_user(user)

            return Response(
                {
                    "user": {
                        "id": user.id,
                        "full_name": user.full_name,
                        "email": user.email,
                    },
                    "tokens": tokens,
                },
                status=status.HTTP_201_CREATED,
                # 201 = Created. Use this instead of 200 when a resource is created.
            )

        # If validation fails, return the error messages.
        # DRF serializers collect all errors across all fields before returning.
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    POST /api/users/login/

    Authenticates a user by email + password and returns JWT tokens.
    AllowAny: unauthenticated users need to be able to call this.
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

        # We look up the user by email manually,
        # then verify the password using check_password().
        # check_password() hashes the provided password and compares it
        # to the stored hash — it never compares plain text.
        from django.contrib.auth import get_user_model
        User = get_user_model()

        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            # Use a generic error message. Never reveal whether the email exists.
            # Saying "email not found" vs "wrong password" helps attackers enumerate users.
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

        tokens = get_tokens_for_user(user)

        return Response(
            {
                "user": {
                    "id": user.id,
                    "full_name": user.full_name,
                    "email": user.email,
                },
                "tokens": tokens,
            },
            status=status.HTTP_200_OK,
        )


class MeView(APIView):
    """
    GET /api/users/me/

    Returns the profile of the currently authenticated user.
    IsAuthenticated: requires a valid JWT access token in the Authorization header.

    DRF + SimpleJWT automatically:
      1. Reads the Authorization: Bearer <token> header
      2. Decodes and verifies the JWT
      3. Looks up the user from the token's user_id claim
      4. Sets request.user to that user
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserDetailSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)