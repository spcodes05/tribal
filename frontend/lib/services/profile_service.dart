import 'package:dio/dio.dart';
import 'dart:io';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/activity_model.dart';
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

  /// POST /api/users/me/profile-image/ (multipart) — Tribe Status avatar tap.
  /// Returns the updated core profile (with the new photo URL) so the
  /// caller can update state immediately, no extra round trip needed.
  Future<ProfileCore> uploadProfileImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await _dio.post(ApiConfig.meProfileImage, data: formData);
      return ProfileCore.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /api/users/me/profile-image/ — "Remove Photo" option.
  Future<ProfileCore> removeProfileImage() async {
    try {
      final response = await _dio.delete(ApiConfig.meProfileImage);
      return ProfileCore.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/users/<id>/mutual-activities/
  /// Reuses [ActivityCardModel] — same shape as the Home feed / Tribe
  /// Status upcoming activity, so no new model was needed for this screen.
  Future<List<ActivityCardModel>> getMutualActivities(int userId) async {
    try {
      final response = await _dio.get(ApiConfig.mutualActivities(userId));
      final list = (response.data as Map<String, dynamic>)['activities'] as List<dynamic>;
      return list.map((e) => ActivityCardModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}