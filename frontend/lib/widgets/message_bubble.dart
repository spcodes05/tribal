import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../models/chat_model.dart';
import '../views/chat/view_location_screen.dart';
import 'location_card.dart';

/// A single chat bubble.
///
/// [isMe] is resolved by the caller (`message.senderId == currentUserId`)
/// since the backend payload has no concept of "me" — see
/// `ConversationController.isMine`.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (message.isLiveLocation) {
      final lat = message.liveLocationLatitude;
      final lng = message.liveLocationLongitude;
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: LocationCard(
          latitude: lat,
          longitude: lng,
          isActive: message.isLiveLocationActive,
          onViewMap: (lat != null && lng != null)
              ? () => context.push(
            AppRoutes.viewLocation,
            extra: ViewLocationArgs(latitude: lat, longitude: lng),
          )
              : null,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          )
              : null,
          color: isMe ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: isMe ? Colors.white.withOpacity(0.75) : AppColors.textSecondary,
                  ),
                ),
                // Read receipt (backend's `is_read` field) — only shown on
                // my own outgoing messages, WhatsApp-style single/double tick.
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}