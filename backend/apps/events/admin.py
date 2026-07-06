from django.contrib import admin
from .models import Activity, ActivityMember, Notification


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['title', 'host', 'location', 'date', 'time', 'member_count', 'is_free']
    list_filter = ['is_women_only', 'is_accessible', 'is_free', 'date']
    search_fields = ['title', 'location', 'host__full_name']
    raw_id_fields = ['host']


@admin.register(ActivityMember)
class ActivityMemberAdmin(admin.ModelAdmin):
    list_display = ['activity', 'user', 'joined_at']
    raw_id_fields = ['activity', 'user']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['recipient', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read']
