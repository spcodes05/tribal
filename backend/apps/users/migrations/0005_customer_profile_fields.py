import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models
 
 
class Migration(migrations.Migration):
 
    dependencies = [
        ('users', '0004_customuser_latitude_customuser_longitude'),
    ]
 
    operations = [
        migrations.AddField(
            model_name='customuser',
            name='username',
            field=models.CharField(blank=True, max_length=30, null=True, unique=True),
        ),
        migrations.AddField(
            model_name='customuser',
            name='profile_image',
            field=models.URLField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='customuser',
            name='bio',
            field=models.CharField(blank=True, default='', max_length=280),
        ),
        migrations.AddField(
            model_name='customuser',
            name='age',
            field=models.PositiveSmallIntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='customuser',
            name='occupation',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='customuser',
            name='university',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='customuser',
            name='location',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.CreateModel(
            name='UserBlock',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('blocked', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='blocked_by', to=settings.AUTH_USER_MODEL)),
                ('blocker', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='blocking', to=settings.AUTH_USER_MODEL)),
            ],
            options={'unique_together': {('blocker', 'blocked')}},
        ),
        migrations.CreateModel(
            name='UserReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('reason', models.CharField(choices=[('harassment', 'Harassment or bullying'), ('spam', 'Spam'), ('fake_profile', 'Fake profile'), ('inappropriate_content', 'Inappropriate content'), ('safety_concern', 'Safety concern'), ('other', 'Other')], max_length=30)),
                ('details', models.TextField(blank=True, default='')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('reported_user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports_received', to=settings.AUTH_USER_MODEL)),
                ('reporter', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports_made', to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]