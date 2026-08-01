import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/conversation_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_model.dart';
import '../../services/chat_socket_service.dart';
import '../../widgets/message_bubble.dart';
import '../../core/routes/app_routes.dart';

/// The 1:1 conversation screen.
///
/// Loads history from `GET /api/chat/<id>/` and opens a WebSocket
/// (`ws/chat/<id>/`) for real-time delivery via [ConversationController].
class ChatScreen extends StatelessWidget {
  final ChatConversationArgs args;
  const ChatScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversationController(chatId: args.chatId),
      child: _ChatView(args: args),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ChatConversationArgs args;
  const _ChatView({required this.args});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ConversationController>().initialize();
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend() async {
    final text = _inputController.text;
    if (text
        .trim()
        .isEmpty) return;
    _inputController.clear();

    final ctrl = context.read<ConversationController>();
    final ok = await ctrl.sendMessage(text);

    if (!mounted) return;
    if (!ok && ctrl.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ConversationController>();

    // Auto-scroll only when a new message actually arrives, not on every
    // unrelated rebuild (e.g. the send button's loading spinner toggling).
    if (ctrl.messages.length != _lastMessageCount) {
      _lastMessageCount = ctrl.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        titleSpacing: 0,
        title: _ConversationHeader(
            args: widget.args, socketStatus: ctrl.socketStatus),
        actions: [
          IconButton(
            onPressed: () => _showMenuSheet(context),
            icon: const Icon(
                Icons.more_vert_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(ctrl)),
            _MessageInputBar(
              controller: _inputController,
              isSending: ctrl.isSending,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ConversationController ctrl) {
    if (ctrl.isLoading && ctrl.messages.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (ctrl.error != null && ctrl.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctrl.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ctrl.retry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hi 👋',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ctrl.messages.length,
      itemBuilder: (context, i) {
        final message = ctrl.messages[i];
        return MessageBubble(message: message, isMe: ctrl.isMine(message));
      },
    );
  }

  void _showMenuSheet(BuildContext context) {
    final otherUserId = widget.args.otherUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  label: 'View profile',
                  onTap: otherUserId == null
                      ? null
                      : () {
                    Navigator.of(context).pop();
                    context.push(
                      AppRoutes.otherUserProfilePath(otherUserId),
                    );
                  },
                ),
                _MenuTile(icon: Icons.notifications_off_outlined,
                    label: 'Mute notifications'),
                _MenuTile(icon: Icons.block_rounded,
                    label: 'Block',
                    isDestructive: true),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
}

// =============================================================================
// AppBar title — avatar, name, connection status
// =============================================================================

class _ConversationHeader extends StatelessWidget {
  final ChatConversationArgs args;
  final ChatSocketStatus socketStatus;
  const _ConversationHeader({required this.args, required this.socketStatus});

  String get _initials {
    final parts = args.otherUserFullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Color get _avatarColor {
    const palette = [
      Color(0xFFC0392B), Color(0xFF2E6F95), Color(0xFF7A4FB5),
      Color(0xFF1F8A5F), Color(0xFFB5762F), Color(0xFF3B6E8F),
    ];
    return palette[args.chatId % palette.length];
  }

  // Reflects OUR connection to the realtime channel — NOT the other
  // participant's presence (the backend has no online/last-seen field, so
  // we never claim to know that).
  String? get _statusLabel {
    switch (socketStatus) {
      case ChatSocketStatus.connecting:
        return 'Connecting...';
      case ChatSocketStatus.disconnected:
      case ChatSocketStatus.error:
        return 'Reconnecting...';
      case ChatSocketStatus.connected:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = args.otherUserProfileImage != null && args.otherUserProfileImage!.isNotEmpty;
    final status = _statusLabel;

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: _avatarColor,
          backgroundImage: hasImage ? NetworkImage(args.otherUserProfileImage!) : null,
          child: hasImage
              ? null
              : Text(
            _initials,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              args.otherUserFullName,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (status != null)
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Bottom message input bar
// =============================================================================

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSending
                  ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Menu sheet tile
// =============================================================================

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, this.isDestructive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      ),
      onTap: onTap ?? () => Navigator.of(context).pop(),
    );
  }
}