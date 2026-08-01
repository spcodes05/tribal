import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/profile_model.dart';

/// Talks to the new profile endpoints in `backend/apps/users/`.
/// Same convention as [AuthService] / [ChatService] / [RoommateService]:
/// every method throws an [ApiException] on failure.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/users/me/tribe-status/
  Future<TribeStatusModel> getTribeStatus() async {
    try {
      final response = await _dio.get(ApiConfig.meTribeStatus);
      return TribeStatusModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/users/<id>/profile/
  Future<PublicProfileModel> getPublicProfile(int userId) async {
    try {
      final response = await _dio.get(ApiConfig.publicProfile(userId));
      return PublicProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/users/me/update/ — Profile Settings screen.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.patch(ApiConfig.meUpdateProfile, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/users/<id>/block/
  Future<void> blockUser(int userId) async {
    try {
      await _dio.post(ApiConfig.blockUser(userId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /api/users/<id>/block/
  Future<void> unblockUser(int userId) async {
    try {
      await _dio.delete(ApiConfig.blockUser(userId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/users/<id>/report/
  Future<void> reportUser(int userId, {required String reason, String details = ''}) async {
    try {
      await _dio.post(
        ApiConfig.reportUser(userId),
        data: {'reason': reason, 'details': details},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}