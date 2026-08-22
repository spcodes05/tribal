import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

from django.core.asgi import get_asgi_application

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter
from apps.chat import routing
from apps.chat.middleware import JWTAuthMiddleware

# TEMPORARY DIAGNOSTIC: prints once when the ASGI worker boots, so a
# `grep ASGI_BOOT` on the Render logs tells you definitively whether the
# deployed worker is running JWTAuthMiddleware (this file) or an older
# build still using AuthMiddlewareStack. Safe to remove once the fix is
# confirmed live in production.
print("ASGI_BOOT: websocket stack = JWTAuthMiddleware(URLRouter(...))")

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,

        "websocket": JWTAuthMiddleware(
            URLRouter(routing.websocket_urlpatterns)
        ),
    }
)