# Converts profile_image to a real ImageField so uploaded photos are
# stored on disk (media/profile_images/) instead of only accepting URLs.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_customer_profile_fields'),
    ]

    operations = [
        migrations.AlterField(
            model_name='customuser',
            name='profile_image',
            field=models.ImageField(blank=True, default='', upload_to='profile_images/'),
        ),
    ]