class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final double totalEarnings;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.totalEarnings,
  });
}
