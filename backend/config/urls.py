from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.http import JsonResponse

def home(request):
    return JsonResponse({
        "status": "ok",
        "message": "TRIBAL backend is running"
    })

urlpatterns = [
    path("", home),

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