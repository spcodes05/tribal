from django.urls import path
from .views import SafetySettingsView

urlpatterns = [
    path("settings/", SafetySettingsView.as_view(), name="safety-settings"),
]