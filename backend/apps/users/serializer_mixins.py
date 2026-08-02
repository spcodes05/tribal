"""
Centralized profile-image URL handling for the whole backend.

Every serializer that needs to expose a user's photo (HostSerializer,
MemberSerializer, PeopleMatchSerializer, PublicUserProfileSerializer,
RoommateProfileSummarySerializer, ...) mixes this in instead of writing
its own get_profile_image method. This is the ONE place that:

  - Returns None for users with no photo (never an empty string / fake URL)
  - Builds a full absolute http(s):// URL from the request, never a bare
    relative /media/... path and never a file:/// path
"""


class ProfileImageMixin:
    def build_profile_image_url(self, user):
        if not user or not getattr(user, "profile_image", None):
            return None
        request = self.context.get("request")
        url = user.profile_image.url
        return request.build_absolute_uri(url) if request else url