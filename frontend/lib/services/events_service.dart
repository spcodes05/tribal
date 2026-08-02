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

  // ── Interests (for tag picker in Create Activity) ─────────────────────────

  /// GET /api/users/interests/ — returns [{id, name}] of all interests.
  /// Used to populate the tag picker in CreateActivityScreen.
  Future<List<Map<String, dynamic>>> fetchInterests() async {
    try {
      final res = await _dio.get(ApiConfig.interestsList);
      return (res.data as List).cast<Map<String, dynamic>>();
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

  // ── Map pins ──────────────────────────────────────────────────────────────

  /// GET /api/events/activities/map/
  /// Supports optional query params: tag, is_free, is_women_only, this_weekend
  Future<List<ActivityPinModel>> getActivityPins({
    String? tag,
    bool? isFree,
    bool? isWomenOnly,
    bool? thisWeekend,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (tag != null) params['tag'] = tag;
      if (isFree == true) params['is_free'] = 'true';
      if (isWomenOnly == true) params['is_women_only'] = 'true';
      if (thisWeekend == true) params['this_weekend'] = 'true';

      final res = await _dio.get(
        ApiConfig.activitiesMap,
        queryParameters: params.isEmpty ? null : params,
      );
      return (res.data as List)
          .map((e) => ActivityPinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}