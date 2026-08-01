from django.urls import path
from .views import (
    SafetySettingsView,
    TrustedContactListCreateView,
    TrustedContactDeleteView,
)

urlpatterns = [
    path("settings/", SafetySettingsView.as_view(), name="safety-settings"),
    path(
        "trusted-contacts/",
        TrustedContactListCreateView.as_view(),
        name="trusted-contact-list-create",
    ),

    path(
        "trusted-contacts/<int:pk>/",
        TrustedContactDeleteView.as_view(),
        name="trusted-contact-delete",
    ),
]