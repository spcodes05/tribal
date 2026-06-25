from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),

    # All user-related endpoints live under /api/users/
    # include() delegates routing to the users app's own urls.py
    path("api/users/", include("apps.users.urls")),
]