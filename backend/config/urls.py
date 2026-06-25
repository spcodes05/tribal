from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path("admin/", admin.site.urls),

    # All user-related endpoints live under /api/users/
    # include() delegates routing to the users app's own urls.py
    path("api/users/", include("apps.users.urls")),
     path("api/token/", TokenObtainPairView.as_view()),
    path("api/token/refresh/", TokenRefreshView.as_view()),
]