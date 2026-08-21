"""
Helpers for activity expiry.

An activity is "expired" once its date + time has passed relative to the
current moment. Two things use this:

1. `filter_active()` — excludes expired activities from any queryset used
   in a listing/search/map endpoint, so they disappear from the app
   immediately once their time passes (even before cleanup has run).

2. `delete_expired_activities()` — actually deletes expired Activity rows
   from the database. Called opportunistically from HomeFeedView (so the
   app self-cleans without needing a task queue) and also exposed as a
   management command (`python manage.py delete_expired_activities`) for
   proper scheduling via cron / Task Scheduler in a real deployment.
"""

from django.db.models import Q
from django.utils import timezone


def _now_date_time():
    now = timezone.localtime()
    return now.date(), now.time()


def filter_active(queryset):
    """Returns only activities whose date/time hasn't passed yet."""
    today, current_time = _now_date_time()
    return queryset.filter(
        Q(date__gt=today) | Q(date=today, time__gte=current_time)
    )


def delete_expired_activities():
    """
    Deletes all activities whose date/time has passed.
    Returns the number of activities deleted.
    """
    from .models import Activity  # local import avoids circular import

    today, current_time = _now_date_time()
    expired = Activity.objects.filter(
        Q(date__lt=today) | Q(date=today, time__lt=current_time)
    )
    count = expired.count()
    expired.delete()
    return count