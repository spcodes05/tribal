/// Data models for the Home screen.
///
/// Kept intentionally lightweight — backend responses will map into these
/// once the API layer is wired up.

class PersonMatch {
  final String name;
  final int matchPercent;
  final List<String> interests;
  final String? avatarUrl;

  const PersonMatch({
    required this.name,
    required this.matchPercent,
    required this.interests,
    this.avatarUrl,
  });
}

class ActivityCard {
  final String title;
  final String distanceKm;
  final int matchPercent;
  final String? imageUrl;

  const ActivityCard({
    required this.title,
    required this.distanceKm,
    required this.matchPercent,
    this.imageUrl,
  });
}