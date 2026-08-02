from django.urls import path
from .views import (
    HomeFeedView,
    ActivityListCreateView,
    ActivityDetailView,
    JoinActivityView,
    NotificationListView,
    MarkNotificationsReadView,
    SearchView,
    ActivityMapView,
)

urlpatterns = [
    path('home/', HomeFeedView.as_view(), name='home-feed'),
    path('activities/', ActivityListCreateView.as_view(), name='activity-list-create'),
    path('activities/map/', ActivityMapView.as_view(), name='activity-map'),
    path('activities/<int:pk>/', ActivityDetailView.as_view(), name='activity-detail'),
    path('activities/<int:pk>/join/', JoinActivityView.as_view(), name='activity-join'),
    path('notifications/', NotificationListView.as_view(), name='notifications'),
    path('notifications/read/', MarkNotificationsReadView.as_view(), name='notifications-read'),
    path('search/', SearchView.as_view(), name='search'),
]