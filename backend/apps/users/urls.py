from django.urls import path
from .views import RegisterView, LoginView, MeView

# These paths are relative — they'll be prefixed by whatever
# the root urls.py mounts them under (e.g., /api/users/).
urlpatterns = [
    path("register/", RegisterView.as_view(), name="user-register"),
    path("login/", LoginView.as_view(), name="user-login"),
    path("me/", MeView.as_view(), name="user-me"),
]
