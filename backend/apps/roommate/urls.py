from django.urls import path

from .views import (
    FindRoommatesView,
    RefreshRoommateMatchesView,
    RoommateProfileView,
)

app_name = "roommate"

urlpatterns = [
    path("profile/", RoommateProfileView.as_view(), name="roommate-profile"),
    path("find/", FindRoommatesView.as_view(), name="find-roommates"),
    path("matches/refresh/", RefreshRoommateMatchesView.as_view(), name="refresh-matches"),
]