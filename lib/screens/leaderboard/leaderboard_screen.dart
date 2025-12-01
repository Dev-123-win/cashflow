import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/app_constants.dart';

import '../../providers/user_provider.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboardData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    _timeLeft = tomorrow.difference(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _fetchLeaderboard();
          final now = DateTime.now().toUtc();
          final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
          _timeLeft = tomorrow.difference(now);
        }
      });
    });
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('leaderboard_data');
      final cachedTime = prefs.getInt('leaderboard_timestamp');

      if (cachedData != null && cachedTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - cachedTime < 3600000) {
          final data = json.decode(cachedData);
          if (mounted) {
            setState(() {
              _leaderboardData = data;
              _isLoading = false;
            });
          }
        }
      }

      const workerUrl =
          '${AppConstants.baseUrl}${AppConstants.leaderboardEndpoint}';

      final response = await http.get(Uri.parse(workerUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final leaderboard = data['leaderboard'] ?? [];

          await prefs.setString('leaderboard_data', json.encode(leaderboard));
          await prefs.setInt(
            'leaderboard_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );

          if (mounted) {
            setState(() {
              _leaderboardData = leaderboard;
              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to load leaderboard');
        }
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;
    final accentColor = isDark ? AppColors.accentDark : AppColors.accent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Timer Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: accentColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'Updates in: ${_formatDuration(_timeLeft)}',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchLeaderboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _leaderboardData.isEmpty
                ? const Center(child: Text('No leaderboard data yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboardData.length,
                    itemBuilder: (context, index) {
                      final userData = _leaderboardData[index];
                      final rank = index + 1;
                      final currentUser = context.read<UserProvider>().user;
                      final isCurrentUser =
                          userData['userId'] == currentUser.id;

                      return _LeaderboardCard(
                        rank: rank,
                        name: userData['displayName'] ?? 'Unknown',
                        avatar: userData['profilePicture'],
                        earnings: (userData['totalEarned'] ?? 0).toDouble(),
                        isCurrentUser: isCurrentUser,
                        userId: userData['userId'] ?? '',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final String name;
  final String? avatar;
  final double earnings;
  final bool isCurrentUser;
  final String userId;

  const _LeaderboardCard({
    required this.rank,
    required this.name,
    this.avatar,
    required this.earnings,
    required this.isCurrentUser,
    required this.userId,
  });

  Color _getMedalColor(bool isDark) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
    }
  }

  String _getMedalEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return ScaleButton(
      onTap: () {}, // Optional: Show user profile
      child: ZenCard(
        padding: const EdgeInsets.all(12),
        color: isCurrentUser
            ? primaryColor.withValues(alpha: 0.1)
            : surfaceColor,
        border: isCurrentUser
            ? Border.all(color: primaryColor, width: 2)
            : null,
        child: Row(
          children: [
            // Medal/Rank
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getMedalColor(isDark).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getMedalEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? primaryColor : textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earned: ₹${earnings.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Earnings Display
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${earnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
