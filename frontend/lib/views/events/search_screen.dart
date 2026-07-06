import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../widgets/tribal_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    context.read<HomeController>().clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) => Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const TribalBottomNav(),
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          title: _SearchField(
            controller: _searchController,
            onChanged: (q) => ctrl.search(q),
          ),
        ),
        body: _searchController.text.trim().isEmpty
            ? _SearchHint()
            : ctrl.isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _SearchResults(
                    activities: ctrl.searchActivities,
                    people: ctrl.searchPeople,
                  ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Find activities or people...',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
        border: InputBorder.none,
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  context.read<HomeController>().clearSearch();
                },
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 20),
              )
            : null,
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Search activities or people',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Try "Hiking", "Music", or a name',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<ActivityCardModel> activities;
  final List<PersonMatchModel> people;
  const _SearchResults({required this.activities, required this.people});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty && people.isEmpty) {
      return Center(
        child: Text('No results found.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (activities.isNotEmpty) ...[
          _SectionLabel('Activities (${activities.length})'),
          const SizedBox(height: 10),
          ...activities.map((a) => _ActivityResultTile(activity: a)),
        ],
        if (people.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel('People (${people.length})'),
          const SizedBox(height: 10),
          ...people.map((p) => _PersonResultTile(person: p)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
}

class _ActivityResultTile extends StatelessWidget {
  final ActivityCardModel activity;
  const _ActivityResultTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.activityDetail, extra: activity.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.divider,
              ),
              child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(activity.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.landscape_rounded, color: Colors.white54)))
                  : const Icon(Icons.landscape_rounded, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.textHint, size: 12),
                      const SizedBox(width: 3),
                      Text(activity.location,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PersonResultTile extends StatelessWidget {
  final PersonMatchModel person;
  const _PersonResultTile({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.divider,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (person.interests.isNotEmpty)
                  Text(person.interests.take(3).join(' · '),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
