import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

from django.core.asgi import get_asgi_application

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter
from apps.chat import routing
from apps.chat.middleware import JWTAuthMiddleware

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,

        "websocket": JWTAuthMiddleware(
            URLRouter(routing.websocket_urlpatterns)
        ),
    }
)