import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/leaderboard_model.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late List<LeaderboardEntry> leaderboard;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    // Mock data for demonstration
    leaderboard = [
      LeaderboardEntry(
        rank: 1,
        userId: 'user1',
        displayName: 'Rajesh K.',
        totalEarnings: 250500, // Coins
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 'user2',
        displayName: 'Priya S.',
        totalEarnings: 180750,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 'user3',
        displayName: 'Amit P.',
        totalEarnings: 165250,
      ),
      LeaderboardEntry(
        rank: 4,
        userId: 'user4',
        displayName: 'Sneha T.',
        totalEarnings: 142100,
      ),
      LeaderboardEntry(
        rank: 5,
        userId: 'user5',
        displayName: 'Vikram R.',
        totalEarnings: 125500,
      ),
    ];
  }

  String _getMedal(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${rank.toString()}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Top Earners',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Compete with others and earn rewards',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Top 3 Highlighted
              if (leaderboard.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2nd place
                      if (leaderboard.length > 1)
                        Expanded(
                          child: _HighlightedRankCard(
                            rank: leaderboard[1].rank,
                            name: leaderboard[1].displayName,
                            earnings: leaderboard[1].totalEarnings,
                            medal: _getMedal(leaderboard[1].rank),
                            position: 'second',
                          ),
                        ),
                      const SizedBox(width: AppTheme.space8),

                      // 1st place
                      Expanded(
                        flex: 1,
                        child: _HighlightedRankCard(
                          rank: leaderboard[0].rank,
                          name: leaderboard[0].displayName,
                          earnings: leaderboard[0].totalEarnings,
                          medal: _getMedal(leaderboard[0].rank),
                          position: 'first',
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),

                      // 3rd place
                      if (leaderboard.length > 2)
                        Expanded(
                          child: _HighlightedRankCard(
                            rank: leaderboard[2].rank,
                            name: leaderboard[2].displayName,
                            earnings: leaderboard[2].totalEarnings,
                            medal: _getMedal(leaderboard[2].rank),
                            position: 'third',
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppTheme.space32),

              // Full Leaderboard
              Text(
                'Full Rankings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaderboard.length > 3 ? leaderboard.length - 3 : 0,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index + 3];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: ZenCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.rank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.displayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${entry.totalEarnings.toInt()} Coins',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final double earnings;
  final String medal;
  final String position;

  const _HighlightedRankCard({
    required this.rank,
    required this.name,
    required this.earnings,
    required this.medal,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = position == 'first';

    return ScaleButton(
      onTap: () {},
      child: Container(
        height: isFirst ? 200 : 160,
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: isFirst ? AppTheme.elevatedShadow : AppTheme.softShadow,
          border: isFirst
              ? Border.all(
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(medal, style: TextStyle(fontSize: isFirst ? 40 : 32)),
            const SizedBox(height: AppTheme.space8),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                '${earnings.toInt()} Coins',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
