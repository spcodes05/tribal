from django.db import migrations

INTERESTS = [
    "Hiking",
    "Futsal",
    "Board Games",
    "Book Club",
    "Photography",
    "Cooking",
    "Travel",
    "Music",
    "Gaming",
    "Yoga",
    "Language",
    "Treks",
]


def seed_interests(apps, schema_editor):
    """
    Inserts predefined interests into the database.

    We use apps.get_model() instead of importing the model directly.
    This is the correct Django pattern inside migrations — it gives us
    the model as it existed at this point in migration history, not
    the current version. This prevents future model changes from
    breaking old migrations.
    """
    Interest = apps.get_model("users", "Interest")
    for name in INTERESTS:
        Interest.objects.get_or_create(name=name)
        # get_or_create is idempotent: running this migration twice
        # won't create duplicate interests.


def unseed_interests(apps, schema_editor):
    """
    Reverse function: removes seeded interests.
    Called if you run: python manage.py migrate users 0002
    to roll back to the previous migration.
    """
    Interest = apps.get_model("users", "Interest")
    Interest.objects.filter(name__in=INTERESTS).delete()


class Migration(migrations.Migration):

    dependencies = [
    ("users", "0002_interest_customuser_gender_and_more"),
]

    operations = [
        migrations.RunPython(seed_interests, reverse_code=unseed_interests),
    ]