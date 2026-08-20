from django.shortcuts import render

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import (
    RoommateMatchResultSerializer,
    RoommateProfileSerializer,
)
from .services import (
    RoommateProfileNotFoundError,
    persist_matches_for_user,
    refresh_matches_if_stale,
)


class RoommateProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            from .services import get_active_profile_for_user

            profile = get_active_profile_for_user(request.user)
        except RoommateProfileNotFoundError:
            return Response(
                {"detail": "No roommate profile found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = RoommateProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        from .models import RoommateProfile

        if RoommateProfile.objects.filter(user=request.user).exists():
            return Response(
                {"detail": "Roommate profile already exists. Use PUT to update."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RoommateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        self._recalculate_matches(request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def put(self, request):
        try:
            from .services import get_active_profile_for_user

            profile = get_active_profile_for_user(request.user)
        except RoommateProfileNotFoundError:
            return Response(
                {"detail": "No roommate profile found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = RoommateProfileSerializer(
            profile, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        self._recalculate_matches(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def _recalculate_matches(self, user):
        try:
            persist_matches_for_user(user)
        except RoommateProfileNotFoundError:
            pass


class FindRoommatesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        limit_param = request.query_params.get("limit", "20")
        min_score_param = request.query_params.get("min_score", "0")
        force_refresh = request.query_params.get("force_refresh", "false").lower() == "true"

        try:
            limit = int(limit_param)
        except (TypeError, ValueError):
            return Response(
                {"detail": "limit must be an integer."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            min_score = float(min_score_param)
        except (TypeError, ValueError):
            return Response(
                {"detail": "min_score must be a number."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if limit <= 0:
            return Response(
                {"detail": "limit must be a positive integer."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            if force_refresh:
                matches = persist_matches_for_user(
                    request.user, limit=limit, min_score=min_score
                )
            else:
                matches = refresh_matches_if_stale(request.user, limit=limit)
        except RoommateProfileNotFoundError:
            return Response(
                {"detail": "You must create a roommate profile before finding matches."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RoommateMatchResultSerializer(matches, many=True, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class RefreshRoommateMatchesView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        limit_param = request.query_params.get("limit", "20")

        try:
            limit = int(limit_param)
        except (TypeError, ValueError):
            return Response(
                {"detail": "limit must be an integer."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            matches = persist_matches_for_user(request.user, limit=limit)
        except RoommateProfileNotFoundError:
            return Response(
                {"detail": "You must create a roommate profile before finding matches."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RoommateMatchResultSerializer(matches, many=True, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)


    
