class EpgProgramme {
  final String channelId; // matches tvg-id
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  const EpgProgramme({
    required this.channelId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });

  /// Whether this programme is currently airing.
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Progress through the programme as a 0.0–1.0 fraction.
  double get progressPercent {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Time remaining until the programme ends.
  Duration get timeRemaining => end.difference(DateTime.now());
}
