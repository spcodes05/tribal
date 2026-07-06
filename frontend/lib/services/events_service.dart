import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/activity_model.dart';

/// Service layer for the Events / Activities feature.
/// All methods throw [ApiException] on failure.
class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  Dio get _dio => ApiClient.instance.dio;

  // ── Home feed ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getHomeFeed() async {
    try {
      final res = await _dio.get(ApiConfig.homeFeed);
      final data = res.data as Map<String, dynamic>;
      return {
        'activities': (data['activities'] as List)
            .map((e) => ActivityCardModel.fromJson(e))
            .toList(),
        'people': (data['people'] as List)
            .map((e) => PersonMatchModel.fromJson(e))
            .toList(),
        'unread_notifications': data['unread_notifications'] as int? ?? 0,
      };
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Activities ─────────────────────────────────────────────────────────────

  Future<List<ActivityCardModel>> getActivities() async {
    try {
      final res = await _dio.get(ApiConfig.activities);
      return (res.data as List)
          .map((e) => ActivityCardModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ActivityDetailModel> getActivityDetail(int id) async {
    try {
      final res = await _dio.get(ApiConfig.activityDetail(id));
      return ActivityDetailModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> joinActivity(int id) async {
    try {
      final res = await _dio.post(ApiConfig.joinActivity(id));
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> leaveActivity(int id) async {
    try {
      final res = await _dio.delete(ApiConfig.joinActivity(id));
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ActivityDetailModel> createActivity(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiConfig.activities, data: data);
      return ActivityDetailModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await _dio.get(ApiConfig.notifications);
      return (res.data as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.post(ApiConfig.notificationsRead);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final res = await _dio.get(
        ApiConfig.search,
        queryParameters: {'q': query},
      );
      final data = res.data as Map<String, dynamic>;
      return {
        'activities': (data['activities'] as List)
            .map((e) => ActivityCardModel.fromJson(e))
            .toList(),
        'people': (data['people'] as List)
            .map((e) => PersonMatchModel.fromJson(e))
            .toList(),
      };
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
