import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_list_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/tribal_bottom_nav.dart';

/// "Messages" — the Chat List screen.
///
/// Backed by `GET /api/chat/` via [ChatListController]. Tapping a row
/// pushes [ChatScreen] (conversation) for that contact.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListController(),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatefulWidget {
  const _ChatListView();

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatListController>().loadChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ChatListController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const TribalBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep in touch with your tribe.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (v) => context.read<ChatListController>().setQuery(v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatListController ctrl) {
    if (ctrl.isLoading && ctrl.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (ctrl.error != null && ctrl.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctrl.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ctrl.loadChats,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chats = ctrl.filteredChats;

    if (chats.isEmpty) {
      return _EmptyState(query: ctrl.query);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: ctrl.loadChats,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chats.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        itemBuilder: (context, i) {
          final chat = chats[i];
          return ChatTile(
            chat: chat,
            currentUserId: ctrl.currentUserId,
            onTap: () => context.push(
              AppRoutes.chatConversation.replaceFirst(':id', chat.id.toString()),
              extra: ChatConversationArgs(
                chatId: chat.id,
                otherUserFullName: chat.otherUserFullName,
                otherUserProfileImage: chat.otherUserProfileImage,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Search bar
// =============================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search people...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              controller.clear();
              onChanged('');
            },
            child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
          )
              : null,
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state (no conversations / no matches)
// =============================================================================

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              query.trim().isEmpty
                  ? 'No conversations yet. Start one from a roommate match.'
                  : 'No results for "$query".',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}