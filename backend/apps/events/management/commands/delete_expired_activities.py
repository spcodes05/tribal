from django.core.management.base import BaseCommand
from apps.events.utils import delete_expired_activities


class Command(BaseCommand):
    help = (
        "Deletes all activities whose date/time has already passed. "
        "Run this on a schedule (cron / Windows Task Scheduler) to keep "
        "the database clean, e.g.:\n"
        "  0 * * * * cd /path/to/backend && python manage.py delete_expired_activities"
    )

    def handle(self, *args, **options):
        count = delete_expired_activities()
        if count:
            self.stdout.write(self.style.SUCCESS(f"Deleted {count} expired activit{'y' if count == 1 else 'ies'}."))
        else:
            self.stdout.write("No expired activities to delete.")