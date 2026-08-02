# Switches profile_image to a UUID-based upload path so every upload gets
# a guaranteed-unique URL — prevents stale client-side image caches from
# ever serving an old photo after a new one is uploaded.

import apps.users.models
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0006_profile_image_imagefield'),
    ]

    operations = [
        migrations.AlterField(
            model_name='customuser',
            name='profile_image',
            field=models.ImageField(blank=True, default='', upload_to=apps.users.models.profile_image_upload_path),
        ),
    ]