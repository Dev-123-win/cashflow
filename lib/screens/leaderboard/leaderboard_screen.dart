import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/leaderboard_model.dart';

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
        totalEarnings: 250.50,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 'user2',
        displayName: 'Priya S.',
        totalEarnings: 180.75,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 'user3',
        displayName: 'Amit P.',
        totalEarnings: 165.25,
      ),
      LeaderboardEntry(
        rank: 4,
        userId: 'user4',
        displayName: 'Sneha T.',
        totalEarnings: 142.10,
      ),
      LeaderboardEntry(
        rank: 5,
        userId: 'user5',
        displayName: 'Vikram R.',
        totalEarnings: 125.50,
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
      appBar: AppBar(title: const Text('Leaderboard'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Top Earners This Month',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Compete with others and earn rewards',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Top 3 Highlighted
              if (leaderboard.isNotEmpty)
                Column(
                  children: [
                    // 2nd place
                    if (leaderboard.length > 1)
                      _HighlightedRankCard(
                        rank: leaderboard[1].rank,
                        name: leaderboard[1].displayName,
                        earnings: leaderboard[1].totalEarnings,
                        medal: _getMedal(leaderboard[1].rank),
                        position: 'second',
                      ),
                    const SizedBox(height: AppTheme.space12),

                    // 1st place
                    _HighlightedRankCard(
                      rank: leaderboard[0].rank,
                      name: leaderboard[0].displayName,
                      earnings: leaderboard[0].totalEarnings,
                      medal: _getMedal(leaderboard[0].rank),
                      position: 'first',
                    ),
                    const SizedBox(height: AppTheme.space12),

                    // 3rd place
                    if (leaderboard.length > 2)
                      _HighlightedRankCard(
                        rank: leaderboard[2].rank,
                        name: leaderboard[2].displayName,
                        earnings: leaderboard[2].totalEarnings,
                        medal: _getMedal(leaderboard[2].rank),
                        position: 'third',
                      ),
                  ],
                ),
              const SizedBox(height: AppTheme.space24),

              // Full Leaderboard
              Text(
                'Full Rankings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space12),
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getMedal(entry.rank),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '#${entry.rank}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${entry.totalEarnings.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppTheme.successColor),
                            ),
                            Text(
                              'earned',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
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

  double get _size {
    switch (position) {
      case 'first':
        return 150;
      case 'second':
        return 120;
      case 'third':
        return 120;
      default:
        return 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _size,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: position == 'first'
              ? [
                  AppTheme.tertiaryColor,
                  AppTheme.tertiaryColor.withValues(alpha: 0.7),
                ]
              : [AppTheme.surfaceColor, AppTheme.surfaceVariant],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            medal,
            style: TextStyle(fontSize: position == 'first' ? 48 : 40),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '₹${earnings.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.successColor),
          ),
        ],
      ),
    );
  }
}
