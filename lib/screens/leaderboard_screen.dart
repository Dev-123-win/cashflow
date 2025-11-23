import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/user_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'allTime'; // allTime, monthly, weekly
  int _selectedPage = 0;
  final int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Time',
                      value: 'allTime',
                      selectedValue: _selectedFilter,
                      onTap: () => setState(() => _selectedFilter = 'allTime'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: 'This Month',
                      value: 'monthly',
                      selectedValue: _selectedFilter,
                      onTap: () => setState(() => _selectedFilter = 'monthly'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: 'This Week',
                      value: 'weekly',
                      selectedValue: _selectedFilter,
                      onTap: () => setState(() => _selectedFilter = 'weekly'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Leaderboard List
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getLeaderboardStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.leaderboard_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No leaderboard data yet',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!;
                final totalPages = (docs.length / _itemsPerPage).ceil();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _itemsPerPage,
                        itemBuilder: (context, index) {
                          final actualIndex =
                              (_selectedPage * _itemsPerPage) + index;
                          if (actualIndex >= docs.length) {
                            return const SizedBox.shrink();
                          }

                          final doc = docs[actualIndex];
                          final userData = doc.data() as Map<String, dynamic>;
                          final rank = actualIndex + 1;
                          final userId = doc.id;
                          final currentUser = context.read<UserProvider>().user;
                          final isCurrentUser = userId == currentUser.id;

                          return _LeaderboardCard(
                            rank: rank,
                            name: userData['displayName'] ?? 'Unknown',
                            avatar: userData['profilePicture'],
                            earnings: (userData['totalEarned'] ?? 0).toDouble(),
                            isCurrentUser: isCurrentUser,
                            userId: userId,
                          );
                        },
                      ),
                    ),
                    // Pagination
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectedPage > 0
                                  ? () => setState(() => _selectedPage--)
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Previous'),
                            ),
                            Text(
                              'Page ${_selectedPage + 1} of $totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _selectedPage < totalPages - 1
                                  ? () => setState(() => _selectedPage++)
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next'),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _getLeaderboardStream() {
    final now = DateTime.now();
    final startDate = _getStartDate(now);

    return _firestore
        .collection('users')
        .orderBy('totalEarned', descending: true)
        .snapshots()
        .map((snapshot) {
          if (_selectedFilter == 'allTime') {
            return snapshot.docs;
          }

          // Filter by date if monthly or weekly
          final filtered = snapshot.docs.where((doc) {
            final userData = doc.data();
            final timestamp = userData['lastGameDate'] as Timestamp?;
            if (timestamp == null) return false;
            return timestamp.toDate().isAfter(startDate);
          }).toList();

          return filtered;
        });
  }

  DateTime _getStartDate(DateTime now) {
    if (_selectedFilter == 'monthly') {
      return DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'weekly') {
      return now.subtract(Duration(days: now.weekday - 1));
    }
    return DateTime.fromMicrosecondsSinceEpoch(0);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
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

  Color _getMedalColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.white,
        border: Border.all(
          color: isCurrentUser ? AppTheme.primaryColor : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medal/Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getMedalColor().withValues(alpha: 0.2),
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
                          color: isCurrentUser
                              ? AppTheme.primaryColor
                              : Colors.black,
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
                          color: AppTheme.primaryColor,
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
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
