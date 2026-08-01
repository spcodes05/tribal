import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';

/// Handles trusted contacts CRUD and user search for the Safety feature.
///
/// Follows the same static-instance + raw Dio pattern as [LocationService].
class TrustedContactsService {
  TrustedContactsService._();
  static final TrustedContactsService instance = TrustedContactsService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Returns the list of trusted contacts for the current user.
  /// Each item: { "id", "owner", "trusted_user", "created_at" }
  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    final response = await _dio.get(ApiConfig.trustedContacts);
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Creates a trusted contact from a selected user id.
  Future<Map<String, dynamic>> addTrustedContact(int trustedUserId) async {
    final response = await _dio.post(
      ApiConfig.trustedContacts,
      data: {'trusted_user': trustedUserId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Deletes a trusted contact by its trusted-contact id (not user id).
  Future<void> deleteTrustedContact(int id) async {
    await _dio.delete(ApiConfig.trustedContactDelete(id));
  }

  /// Searches users by name/email for the "add contact" flow.
  /// Each item: { "id", "full_name", "email" }
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get(
      ApiConfig.userSearch,
      queryParameters: {'query': query},
    );
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}