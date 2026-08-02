import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/chat_model.dart';
import '../../models/profile_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/profile/profile_shared_widgets.dart';
import '../../widgets/user_avatar.dart';

/// FEATURE 2 — "Other User Profile"
/// One reusable screen opened from: "People You Might Vibe With" cards,
/// tapping a person inside Chat, and search results.
class OtherUserProfileScreen extends StatelessWidget {
  final int userId;
  final OtherProfileNavArgs? navArgs;
  const OtherUserProfileScreen({super.key, required this.userId, this.navArgs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadOtherProfile(userId),
      child: _OtherUserProfileView(userId: userId, navArgs: navArgs),
    );
  }
}

class _OtherUserProfileView extends StatefulWidget {
  final int userId;
  final OtherProfileNavArgs? navArgs;
  const _OtherUserProfileView({required this.userId, this.navArgs});

  @override
  State<_OtherUserProfileView> createState() => _OtherUserProfileViewState();
}

class _OtherUserProfileViewState extends State<_OtherUserProfileView> {
  bool _isStartingChat = false;

  Future<void> _handleChat() async {
    setState(() => _isStartingChat = true);
    try {
      // Idempotent server-side (Chat.get_or_create_chat) — never creates a
      // duplicate conversation, matches the "if already chatting, open
      // existing conversation" requirement automatically.
      final chat = await ChatService.instance.startChat(widget.userId);
      if (!mounted) return;
      context.push(
        AppRoutes.chatConversation.replaceFirst(':id', chat.id.toString()),
        extra: ChatConversationArgs(
          chatId: chat.id,
          otherUserId: widget.userId,
          otherUserFullName: chat.otherUserFullName,
          otherUserProfileImage: chat.otherUserProfileImage,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start chat. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _showSafetySheet(BuildContext context, PublicProfileModel profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.textPrimary),
              title: Text('Report User', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showReportSheet(context);
              },
            ),
            ListTile(
              leading: Icon(profile.isBlockedByMe ? Icons.person_add_alt_1_rounded : Icons.block_rounded,
                  color: Colors.redAccent),
              title: Text(
                profile.isBlockedByMe ? 'Unblock User' : 'Block User',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.redAccent),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final ok = await context.read<ProfileController>().toggleBlock(widget.userId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok
                      ? (profile.isBlockedByMe ? 'User unblocked.' : 'User blocked.')
                      : 'Something went wrong.')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    const reasons = <String, String>{
      'harassment': 'Harassment or bullying',
      'spam': 'Spam',
      'fake_profile': 'Fake profile',
      'inappropriate_content': 'Inappropriate content',
      'safety_concern': 'Safety concern',
      'other': 'Other',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Why are you reporting this user?',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              ...reasons.entries.map((e) => ListTile(
                title: Text(e.value, style: GoogleFonts.poppins(fontSize: 13)),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final ok = await context.read<ProfileController>().reportUser(widget.userId, reason: e.key);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Report submitted. Thank you.' : 'Something went wrong.')),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(context, ctrl),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileController ctrl) {
    if (ctrl.isLoading && ctrl.otherProfile == null) {
      return Column(
        children: [
          _header(context, null),
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
        ],
      );
    }

    if (ctrl.error != null && ctrl.otherProfile == null) {
      return Column(
        children: [
          _header(context, null),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ctrl.error!, textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ctrl.loadOtherProfile(widget.userId),
                      child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final profile = ctrl.otherProfile!;
    final core = profile.core;
    final compatibility = profile.compatibilityPercent ?? widget.navArgs?.fallbackMatchPercent;

    return Column(
      children: [
        _header(context, profile),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(child: UserAvatar(imageUrl: core.profileImage, fullName: core.fullName, radius: 48)),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  [core.fullName, if (core.age != null) '${core.age}'].join(', '),
                  style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (core.location != null || core.university != null || core.occupation != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    [core.occupation, core.university, core.location].where((e) => e != null).join(' · '),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ),
              ],

              if (compatibility != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('$compatibility% Compatible',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── About ────────────────────────────────────────────────
              _SectionLabel('About'),
              const SizedBox(height: 8),
              Text(
                core.bio ?? 'No introduction yet.',
                style: GoogleFonts.poppins(
                  fontSize: 13, height: 1.5,
                  color: core.bio != null ? AppColors.textPrimary : AppColors.textHint,
                  fontStyle: core.bio != null ? FontStyle.normal : FontStyle.italic,
                ),
              ),

              // ── Interests ────────────────────────────────────────────
              if (core.interests.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel('Interests'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: core.interests.map((i) => ProfileTag(label: i)).toList()),
              ],

              // ── Mutual Interests ─────────────────────────────────────
              if (profile.mutualInterests.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel('Mutual Interests'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: profile.mutualInterests.map((i) => ProfileTag(label: i, emphasized: true)).toList(),
                ),
              ],

              // ── Tribe Activity ───────────────────────────────────────
              const SizedBox(height: 20),
              _SectionLabel('Tribe Activity'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('${profile.activitiesJoined} activities joined',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              if (profile.recentPublicEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ProfileEmptyState(icon: Icons.event_busy_rounded, title: 'No public activity yet'),
                )
              else
                ...profile.recentPublicEvents.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${e.title} · ${e.location}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                )),

              const SizedBox(height: 28),

              // ── Action Buttons ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isStartingChat ? null : _handleChat,
                  icon: _isStartingChat
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                  label: Text('Chat', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.mutualActivitiesPath(widget.userId)),
                  icon: const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                  label: Text('View Mutual Activities',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, PublicProfileModel? profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const Spacer(),
          if (profile != null)
            IconButton(
              onPressed: () => _showSafetySheet(context, profile),
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}