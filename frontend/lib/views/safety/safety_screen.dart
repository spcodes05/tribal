import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../services/location_service.dart';
import '../../services/trusted_contacts_service.dart';
import '../../widgets/tribal_bottom_nav.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _isActivating = false;
  bool _isLocationSharing = false;
  List<Map<String, dynamic>> _trustedContacts = [];
  int get _trustedContactsCount => _trustedContacts.length;


  @override
  void initState() {
    super.initState();
    _isLocationSharing = LocationService.instance.isLocationSharing;
    _fetchTrustedContacts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchTrustedContacts() async {
    try {
      final contacts = await TrustedContactsService.instance.getTrustedContacts();
      if (mounted) setState(() => _trustedContacts = contacts);
    } catch (_) {
      // Non-critical — keep default empty list
    }
  }

  bool _isTogglingLocation = false;

  Future<void> _toggleLocationSharing(bool value) async {
    if (_isTogglingLocation) return;
    setState(() => _isTogglingLocation = true);

    try {
      // Reuses the existing safety/settings/ endpoint (SafetySettingsView),
      // which now also creates/ends the ONE LiveLocationSession and
      // sends/broadcasts the live-location card — see backend/apps/safety/views.py.
      await ApiClient.instance.dio.patch(
        ApiConfig.safetySettings,
        data: {'live_location_enabled': value},
      );

      if (value) {
        LocationService.instance.startLocationSharing();
      } else {
        LocationService.instance.stopLocationSharing();
      }
      if (mounted) {
        setState(() => _isLocationSharing = LocationService.instance.isLocationSharing);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final apiError = ApiException.fromDio(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiError.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingLocation = false);
    }
  }



  Future<void> _handleSOS() async {
    if (_isActivating) return;
    setState(() => _isActivating = true);

    // Best-effort location update — existing service, failure is non-blocking.
    await LocationService.instance.requestAndSave();

    try {
      final response = await ApiClient.instance.dio.post(ApiConfig.sosActivate);
      if (!mounted) return;

      final message = (response.data is Map && response.data['message'] != null)
          ? response.data['message'] as String
          : 'SOS activated. Your trusted contacts have been notified.';

      final sosmessage = (response.data is Map && response.data['message'] != null)
          ? response.data['message'] as String
          : 'SOS activated. Your trusted contacts have been notified.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sosmessage),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final apiError = ApiException.fromDio(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiError.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // adjust field name if different
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Your Safety',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.primary, // adjust to your maroon color name
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- SOS BUTTON ----------------
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handleSOS,
                      child: Container(
                        width: 260,
                        height: 260,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.06),
                        ),
                        child: Container(
                          width: 190,
                          height: 190,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary, // deep maroon
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _isActivating
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'SOS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _isActivating
                            ? 'Activating...'
                            : 'Hold 2 seconds to activate',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ---------------- LIVE LOCATION SHARING ----------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Location Sharing',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Active during activities',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isLocationSharing,
                      activeColor: AppColors.primary,
                      onChanged: _toggleLocationSharing,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- TRUSTED CONTACTS ----------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trusted Contacts',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Notified in emergency',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/safety/trusted-contacts'),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ..._trustedContacts.take(3).map(
                              (_) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _avatarPlaceholder(),
                          ),
                        ),
                        if (_trustedContacts.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD9D9D9),
                              ),
                              child: Text(
                                '+${_trustedContacts.length - 3}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => context.push('/safety/trusted-contacts'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),



              if (_isLocationSharing) ...[
                const SizedBox(height: 16),

                // ---------------- SAFETY STATUS BANNER ----------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // safe green
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are safe · Location shared with $_trustedContactsCount contacts',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TribalBottomNav(),
    );
  }

  // Small avatar placeholder used only inside this screen — not a separate widget file
  Widget _avatarPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD9D9D9),
      ),
    );
  }
}