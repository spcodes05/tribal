from django.core.mail import send_mail
from django.conf import settings


def send_verification_email(user):
    """
    Sends a verification email to the newly registered user.

    The email contains a link with the user's verification token.
    The frontend will extract the token from the URL and call:
      POST /api/users/verify-email/
      { "token": "<uuid>" }

    In development (console backend), this prints to your terminal.
    In production (SMTP backend), this sends a real email.
    """
    verification_link = (
        f"{settings.FRONTEND_URL}/verify-email?token={user.verification_token}"
    )

    subject = "Verify your Tribal email address"

    message = f"""
Hi {user.full_name},

Welcome to Tribal! Please verify your email address to activate your account.

Click the link below (valid for 24 hours):

{verification_link}

If you did not create an account, you can safely ignore this email.

– The Tribal Team
    """.strip()

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
        # fail_silently=False means if email sending fails, it raises an exception.
        # This is what you want in development. In production you may want to
        # wrap this in a try/except and log the error instead of crashing.
    )