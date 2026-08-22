from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.http import JsonResponse
import os

def home(request):
    return JsonResponse({
        "status": "ok",
        "message": "TRIBAL backend is running"
    })

urlpatterns = [
    path("", home),
        path("debug/redis/", redis_debug),

    path("admin/", admin.site.urls),

    path("api/users/", include("apps.users.urls")),
    path("api/token/", TokenObtainPairView.as_view()),
    path("api/token/refresh/", TokenRefreshView.as_view()),
    path("api/chat/", include("apps.chat.urls")),
    path("api/roommate/", include("apps.roommate.urls")),
    path("api/events/", include("apps.events.urls")),
    path("api/safety/", include("apps.safety.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

def redis_debug(request):
    """
    TEMPORARY DIAGNOSTIC ENDPOINT — remove after the WebSocket/Redis issue
    is confirmed fixed. Does a raw redis-py PING using the same REDIS_URL
    the app uses, completely bypassing Django Channels, so we can tell
    whether the timeout is a network/access problem or a channels_redis
    config problem. Reveals no secrets: only host:port (never password),
    and never the value of REDIS_URL itself.
    """
    redis_url = os.environ.get("REDIS_URL", "")
    safe_target = redis_url.split("@")[-1] if redis_url else "(REDIS_URL not set)"

    result = {"redis_url_is_set": bool(redis_url), "target": safe_target}

    if not redis_url:
        return JsonResponse(result, status=500)

    try:
        import redis
        client = redis.from_url(redis_url, socket_connect_timeout=5, socket_timeout=5)
        pong = client.ping()
        result["ping_ok"] = bool(pong)
        return JsonResponse(result)
    except Exception as e:
        result["ping_ok"] = False
        result["error_type"] = type(e).__name__
        result["error_detail"] = str(e)
        return JsonResponse(result, status=500)