from django.urls import path
from .views import (
    HomeFeedView,
    ActivityListCreateView,
    ActivityDetailView,
    JoinActivityView,
    NotificationListView,
    MarkNotificationsReadView,
    SearchView,
)

urlpatterns = [
    # Home feed (activities + people + unread count in one call)
    path('home/', HomeFeedView.as_view(), name='home-feed'),

    # Activities CRUD
    path('activities/', ActivityListCreateView.as_view(), name='activity-list-create'),
    path('activities/<int:pk>/', ActivityDetailView.as_view(), name='activity-detail'),
    path('activities/<int:pk>/join/', JoinActivityView.as_view(), name='activity-join'),

    # Notifications
    path('notifications/', NotificationListView.as_view(), name='notifications'),
    path('notifications/read/', MarkNotificationsReadView.as_view(), name='notifications-read'),

    # Search
    path('search/', SearchView.as_view(), name='search'),
]
