import logging

from django.core.mail import send_mail
from django.conf import settings

logger = logging.getLogger(__name__)


def send_verification_email(user):
    """
    Sends a verification email to the newly registered user.

    Uses the exact same `verification_token` already generated/stored by
    `CustomUser.generate_verification_token()` — no second token is created.
    The token is shown both as a link (?token=...) and as a plain value,
    since the Flutter verify-email screen lets the user paste the raw token.

    Delivery goes through settings.EMAIL_BACKEND:
      - SMTP backend (default) -> real email sent to user.email
      - console backend (opt-in via .env) -> printed to terminal for local dev
    """
    verification_link = (
        f"{settings.FRONTEND_URL}/verify-email?token={user.verification_token}"
    )

    subject = "Verify your Tribal account"

    message = f"""Welcome to Tribal!

Thank you for creating your Tribal account, {user.full_name}.

Your verification code is:

{user.verification_token}

Enter this code in the Tribal app to verify your email address, or open the link below:

{verification_link}

This code expires 24 hours after it was issued. Do not share it with anyone.

If you did not create this account, you can safely ignore this email.

– The Tribal Team""".strip()

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )