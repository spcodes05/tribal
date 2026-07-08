import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/roommate_match_model.dart';

/// Talks to `backend/apps/roommate/` via the shared [ApiClient].
///
/// Both endpoints require:
///   - a valid JWT access token (attached automatically by [ApiClient])
///   - the user to already have verified their email, same as
///     [OnboardingService] — otherwise the backend returns 403.
class RoommateService {
  RoommateService._();
  static final RoommateService instance = RoommateService._();

  Dio get _dio => ApiClient.instance.dio;

  /// `RoommateProfileSerializer.interests` is a `PrimaryKeyRelatedField`,
  /// so it expects interest IDs, not names. The quiz only stores names
  /// (reusing `kAvailableInterests`), so we resolve names -> ids against
  /// the same predefined list already exposed at `GET /api/users/interests/`
  /// (see `OnboardingService.fetchAvailableInterests`) instead of adding a
  /// duplicate lookup endpoint.
  Future<List<int>> _resolveInterestIds(List<dynamic> names) async {
    if (names.isEmpty) return [];

    try {
      final response = await _dio.get(ApiConfig.interests);
      final data = response.data as Map<String, dynamic>;
      final all = (data['interests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final nameToId = <String, int>{
        for (final item in all) item['name'] as String: item['id'] as int,
      };

      return names
          .map((n) => nameToId[n])
          .whereType<int>()
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/roommate/profile/ (falls back to PUT if a profile already
  /// exists — `RoommateProfileView.post` returns 400 "already exists" in
  /// that case, and the same view supports PUT for partial updates).
  ///
  /// [payload] must be `RoommateQuizModel.toApiJson()` exactly — its
  /// `interests` field (list of names) is resolved to IDs here before
  /// the request is sent.
  Future<Map<String, dynamic>> submitProfile(
      Map<String, dynamic> payload,
      ) async {
    final resolvedPayload = Map<String, dynamic>.from(payload);
    resolvedPayload['interests'] = await _resolveInterestIds(
      (payload['interests'] as List<dynamic>?) ?? [],
    );

    try {
      final response = await _dio.post(
        ApiConfig.roommateProfile,
        data: resolvedPayload,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final apiError = ApiException.fromDio(e);
      final profileAlreadyExists = e.response?.statusCode == 400 &&
          apiError.message.toLowerCase().contains('already exists');

      if (!profileAlreadyExists) throw apiError;

      // Retake flow: user already has a profile, update it instead.
      try {
        final retry = await _dio.put(
          ApiConfig.roommateProfile,
          data: resolvedPayload,
        );
        return retry.data as Map<String, dynamic>;
      } on DioException catch (e2) {
        throw ApiException.fromDio(e2);
      }
    }
  }

  /// GET /api/roommate/find/ — returns cached matches, computing fresh
  /// ones only if stale (see `refresh_matches_if_stale` in services.py).
  Future<List<RoommateMatchResult>> fetchMatches({int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.roommateFind,
        queryParameters: {'limit': limit},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => RoommateMatchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/roommate/matches/refresh/ — forces recomputation. Exposed
  /// for a future "pull to refresh" on the Roommate home screen; not
  /// wired into the UI yet.
  Future<List<RoommateMatchResult>> refreshMatches({int limit = 20}) async {
    try {
      final response = await _dio.post(
        ApiConfig.roommateMatchesRefresh,
        queryParameters: {'limit': limit},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => RoommateMatchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}