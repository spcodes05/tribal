from django.urls import path
from .views import (
    RegisterView,
    VerifyEmailView,
    LoginView,
    GenderView,
    InterestsView,
    MeView,
)
from .views import set_gender, set_interests

urlpatterns = [
    path("register/", RegisterView.as_view(), name="user-register"),
    path("verify-email/", VerifyEmailView.as_view(), name="user-verify-email"),
    path("login/", LoginView.as_view(), name="user-login"),
    path("gender/", GenderView.as_view(), name="user-gender"),
    path("interests/", InterestsView.as_view(), name="user-interests"),
    path("me/", MeView.as_view(), name="user-me"),
    path("set-gender/", set_gender),
    path("set-interests/", set_interests),
]