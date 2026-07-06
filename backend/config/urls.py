from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/users/", include("apps.users.urls")),
    path("api/token/", TokenObtainPairView.as_view()),
    path("api/token/refresh/", TokenRefreshView.as_view()),
    path("api/chat/", include("apps.chat.urls")),
    path("api/roommate/", include("apps.roommate.urls")),
    path("api/events/", include("apps.events.urls")),
]