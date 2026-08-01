from django.urls import path
from .views import (
    RegisterView,
    VerifyEmailView,
    ResendVerificationView,
    LoginView,
    GenderView,
    InterestsView,
    MeView,
    LocationView,
    TribeStatusView,
    UpdateProfileView,
    PublicProfileView,
    BlockUserView,
    ReportUserView,
)
from .views import set_gender, set_interests

urlpatterns = [
    path("register/", RegisterView.as_view(), name="user-register"),
    path("verify-email/", VerifyEmailView.as_view(), name="user-verify-email"),
    path("resend-verification/", ResendVerificationView.as_view(), name="user-resend-verification"),
    path("login/", LoginView.as_view(), name="user-login"),
    path("gender/", GenderView.as_view(), name="user-gender"),
    path("interests/", InterestsView.as_view(), name="user-interests"),
    path("me/", MeView.as_view(), name="user-me"),
    path("location/", LocationView.as_view(), name="user-location"),
    path("set-gender/", set_gender),
    path("set-interests/", set_interests),

    # ── Tribe Status / Other User Profile ──────────────────────────────────
    path("me/tribe-status/", TribeStatusView.as_view(), name="user-tribe-status"),
    path("me/update/", UpdateProfileView.as_view(), name="user-update-profile"),
    path("<int:user_id>/profile/", PublicProfileView.as_view(), name="user-public-profile"),
    path("<int:user_id>/block/", BlockUserView.as_view(), name="user-block"),
    path("<int:user_id>/report/", ReportUserView.as_view(), name="user-report"),
]