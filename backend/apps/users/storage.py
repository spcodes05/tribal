"""
Supabase Storage backend for profile pictures.

This is a drop-in Django Storage implementation, not a separate upload
pipeline. `CustomUser.profile_image` uses this class as its `storage=`,
so every existing call site keeps working unchanged:

    request.user.profile_image = image_file      # -> SupabaseStorage._save
    request.user.profile_image.storage.delete(x)  # -> SupabaseStorage.delete
    user.profile_image.url                        # -> SupabaseStorage.url

apps/users/serializer_mixins.ProfileImageMixin, the upload/delete views,
and every screen that renders `profile_image` (Activity, Trusted
Contacts, Chat, Roommate, People) are untouched — they only ever read
`.url` / the field's truthiness, never the storage mechanism.

The Supabase service-role key is read from settings (env-only) and is
never sent to Flutter; only the resulting public URL is.
"""

import mimetypes

from django.conf import settings
from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible

try:
    from supabase import create_client
except ImportError:  # pragma: no cover - surfaced clearly at first use instead
    create_client = None


@deconstructible
class SupabaseStorage(Storage):
    def __init__(self):
        self._client = None

    @property
    def client(self):
        if self._client is None:
            if create_client is None:
                raise RuntimeError(
                    "The 'supabase' package is not installed. "
                    "Run: pip install -r requirements.txt"
                )
            if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
                raise RuntimeError(
                    "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not configured in .env"
                )
            self._client = create_client(
                settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY
            )
        return self._client

    @property
    def bucket(self):
        return settings.SUPABASE_PROFILE_BUCKET

    def _save(self, name, content):
        content.seek(0)
        data = content.read()
        content_type = (
            getattr(content, "content_type", None)
            or mimetypes.guess_type(name)[0]
            or "application/octet-stream"
        )
        self.client.storage.from_(self.bucket).upload(
            path=name,
            file=data,
            file_options={"content-type": content_type, "upsert": "true"},
        )
        return name

    def _open(self, name, mode="rb"):
        raise NotImplementedError("SupabaseStorage is write/delete/url only.")

    def exists(self, name):
        return False

    def size(self, name):
        return 0

    def url(self, name):
        if not name:
            return None
        return self.client.storage.from_(self.bucket).get_public_url(name)

    def delete(self, name):
        if not name:
            return
        try:
            self.client.storage.from_(self.bucket).remove([name])
        except Exception:
            pass