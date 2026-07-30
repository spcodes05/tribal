import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/chat_model.dart';

/// A single row on the Chat List screen.
///
/// NOTE: the backend has no online/last-seen field for the other
/// participant (see ChatPreviewSerializer), so — unlike the earlier
/// dummy-data version of this widget — there is no online indicator dot.
class ChatTile extends StatelessWidget {
  final ChatPreviewModel chat;
  final VoidCallback onTap;
  final int? currentUserId;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final latest = chat.latestMessage;
    final isMineLatest =
        currentUserId != null && latest != null && latest.senderId == currentUserId;
    final previewText = latest == null
        ? chat.lastMessagePreview
        : (isMineLatest ? 'You: ${latest.content}' : latest.content);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withOpacity(0.06),
        highlightColor: AppColors.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _ChatAvatar(chat: chat),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.otherUserFullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chat.formattedTimestamp,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: chat.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Avatar — real profile image when the backend has one, gradient-ringed
// initials fallback otherwise (`other_user_profile_image` is nullable).
// =============================================================================

class _ChatAvatar extends StatelessWidget {
  final ChatPreviewModel chat;
  const _ChatAvatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    const size = 54.0;
    final hasImage =
        chat.otherUserProfileImage != null && chat.otherUserProfileImage!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [chat.avatarColor.withOpacity(0.9), AppColors.primary],
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
          chat.otherUserProfileImage!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(chat: chat),
        )
            : _InitialsAvatar(chat: chat),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final ChatPreviewModel chat;
  const _InitialsAvatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: chat.avatarColor,
      alignment: Alignment.center,
      child: Text(
        chat.initials,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// =============================================================================
// Unread count badge
// =============================================================================

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}