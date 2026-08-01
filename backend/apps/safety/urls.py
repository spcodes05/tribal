from django.urls import path
from .views import (
    SafetySettingsView,
    TrustedContactListCreateView,
    TrustedContactDeleteView,
    UserLocationUpdateView,
    TrustedUserLocationView,
    SOSActivateView,
)

urlpatterns = [
    path("settings/", SafetySettingsView.as_view(), name="safety-settings"),
    path("trusted-contacts/", TrustedContactListCreateView.as_view(), name="trusted-contacts-list-create"),
    path("trusted-contacts/<int:pk>/", TrustedContactDeleteView.as_view(), name="trusted-contacts-delete"),
    path("location/", UserLocationUpdateView.as_view(), name="user-location-update"),
    path("location/<int:user_id>/", TrustedUserLocationView.as_view(), name="trusted-user-location"),
    path("sos/activate/", SOSActivateView.as_view(), name="sos-activate"),
]