from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import AccessToken

User = get_user_model()


class JWTAuthMiddleware(BaseMiddleware):
    """
    ASGI middleware that authenticates WebSocket connections using a
    SimpleJWT access token passed as a query parameter:

        ws://host/ws/chat/1/?token=<jwt>

    On success, populates scope["user"] with the corresponding
    CustomUser instance. On any failure (missing token, invalid
    token, expired token, unknown user), scope["user"] is set to
    AnonymousUser so downstream consumers can reject the connection
    using their normal authentication checks.
    """

    async def __call__(self, scope, receive, send):
        scope["user"] = await self._get_user_from_scope(scope)
        return await super().__call__(scope, receive, send)

    async def _get_user_from_scope(self, scope):
        token = self._extract_token(scope)
        if not token:
            return AnonymousUser()

        user_id = self._decode_token(token)
        if user_id is None:
            return AnonymousUser()

        return await self._get_user(user_id)

    @staticmethod
    def _extract_token(scope) -> str | None:
        query_string = scope.get("query_string", b"").decode("utf-8")
        query_params = parse_qs(query_string)
        token_list = query_params.get("token")
        if not token_list:
            return None
        return token_list[0]

    @staticmethod
    def _decode_token(token: str):
        try:
            access_token = AccessToken(token)
            return access_token["user_id"]
        except (InvalidToken, TokenError, KeyError):
            return None

    @database_sync_to_async
    def _get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return AnonymousUser()


def JWTAuthMiddlewareStack(inner):
    """Convenience wrapper mirroring Channels' AuthMiddlewareStack pattern."""
    return JWTAuthMiddleware(inner)