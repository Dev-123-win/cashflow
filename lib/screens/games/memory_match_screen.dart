import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/cooldown_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/error_states.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen>
    with TickerProviderStateMixin {
  late final GameService _gameService;
  late final CooldownService _cooldownService;
  late final AdService _adService;
  late MemoryMatchGame _game;
  int? _selectedIndex1;
  int? _selectedIndex2;
  bool _isProcessing = false;
  late AnimationController _matchAnimation;
  late AnimationController _matchPulseAnimation;
  late AnimationController _successAnimation;
  bool _isPreviewMode = true;
  final int _previewSeconds = 3;

  bool _isGameCompleted = false;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _cooldownService = CooldownService();
    _adService = AdService();
    _game = _gameService.createMemoryMatchGame();
    _isGameCompleted = false;

    _matchAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _matchPulseAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _successAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start preview timer
    Future.delayed(Duration(seconds: _previewSeconds), () {
      if (mounted) {
        setState(() {
          _isPreviewMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _matchAnimation.dispose();
    _matchPulseAnimation.dispose();
    _successAnimation.dispose();
    super.dispose();
  }

  Future<void> _handleCardTap(int index) async {
    if (index == 4) return; // Center card

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check Daily Limit
    if (userProvider.user.gamesPlayedToday >= 20) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily game limit reached (20/20). Come back tomorrow!',
        );
      }
      return;
    }

    if (_isProcessing ||
        _game.revealed[index] ||
        _game.matched[index] ||
        _selectedIndex1 == index ||
        _isGameCompleted) {
      return;
    }

    setState(() {
      if (_selectedIndex1 == null) {
        _selectedIndex1 = index;
        _game.revealCard(index);
      } else {
        _selectedIndex2 = index;
        _game.revealCard(index);
        _game.moves++; // Increment moves only when pair is attempted
      }
    });

    if (_selectedIndex1 != null && _selectedIndex2 != null) {
      setState(() => _isProcessing = true);

      await Future.delayed(const Duration(milliseconds: 500));

      final isMatch = _game.checkMatch(_selectedIndex1!, _selectedIndex2!);

      if (isMatch) {
        await _matchAnimation.forward().then((_) {
          _matchAnimation.reset();
        });

        if (_game.isGameOver()) {
          _isGameCompleted = true;
          if (mounted) {
            _showClaimRewardDialog();
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _game.resetCards(_selectedIndex1!, _selectedIndex2!);
      }

      if (mounted) {
        setState(() {
          _selectedIndex1 = null;
          _selectedIndex2 = null;
          _isProcessing = false;
        });
      }
    }
  }

  void _showClaimRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'You Won! 🎉',
        emoji: '🏆',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great memory!'),
            const SizedBox(height: 8),
            const Text('Watch a short ad to claim your Coins!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Claim Reward 📺',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _watchAdToClaim();
            },
            child: const Text('Watch Ad & Claim'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Skip Reward'),
          ),
        ],
      ),
    );
  }

  bool _isClaiming = false;

  Future<void> _watchAdToClaim() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      await _adService.showRewardedAd(
        onRewardEarned: (rewardItem) async {
          if (!mounted) return;

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final accuracy = _game.getAccuracy();

          // Calculate reward based on accuracy
          int reward = 500; // Base 500 Coins
          if (accuracy >= 90) {
            reward = 750;
          } else if (accuracy >= 70) {
            reward = 600;
          }

          // 1. Optimistic Update
          userProvider.addOptimisticCoins(reward);

          // Show success dialog immediately
          if (mounted) {
            _showGameResult(reward);
          }

          // 2. Call Backend with Timeout
          try {
            await _recordGameWin(reward).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Request timed out');
              },
            );
          } catch (e) {
            // 3. Rollback on failure
            userProvider.rollbackOptimisticCoins(reward);
            if (mounted) {
              StateSnackbar.showError(
                context,
                'Failed to save reward: ${e.toString().replaceAll('Exception: ', '')}',
              );
            }
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  Future<void> _recordGameWin(int reward) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check backend health
      final cloudflareService = CloudflareWorkersService();
      final isBackendHealthy = await cloudflareService.healthCheck();
      if (!isBackendHealthy) {
        throw Exception('Backend unreachable');
      }

      await _gameService.recordGameWin(
        userProvider.user.userId,
        'memory_match',
        customReward: reward,
      );

      // We don't need to update local state here as optimistic update handled it.
      // But we might want to sync other stats like gamesPlayedToday.
      // Actually, let's update stats but NOT coins (since we already did).
      // Or better, update everything to be safe and confirm.

      // Since addOptimisticCoins adds to a separate buffer, and updateLocalState updates the base user,
      // we need to be careful.
      // Ideally:
      // 1. Optimistic: _optimisticCoins += 500
      // 2. Backend Success: Returns new total coins (e.g. 10500).
      // 3. We update User.coins = 10500.
      // 4. We clear _optimisticCoins = 0.

      // For now, let's just rely on the optimistic update for the visual
      // and let the next refresh sync the real state.
      // But to be correct with `gamesPlayedToday`, we should update it.

      userProvider.updateLocalState(
        gamesPlayedToday: userProvider.user.gamesPlayedToday + 1,
        // Don't update coins here to avoid double counting if we don't clear optimistic
        // But wait, if we don't update base coins, and we clear optimistic, it flickers back.
        // We need a way to "commit" the optimistic coins.
        // For this iteration, let's just leave optimistic coins as is until next refresh?
        // No, that's risky.
        // Let's use `confirmOptimisticCoins` if we had it, or just:
        // userProvider.confirmOptimisticCoins(reward); // We added this method!
      );

      // Commit the optimistic coins
      userProvider.confirmOptimisticCoins(reward);
      // And update the base user with the new total (approximate or wait for refresh)
      // Actually, confirmOptimisticCoins just subtracts from optimistic.
      // We need to ADD to base user at the same time.
      userProvider.updateLocalState(
        coins: userProvider.user.coins + reward,
        gamesPlayedToday: userProvider.user.gamesPlayedToday + 1,
      );

      _cooldownService.startCooldown(
        userProvider.user.userId,
        'game_memory',
        300,
      );

      debugPrint('✅ Game win recorded');
    } catch (e) {
      debugPrint('Error recording game: $e');
      rethrow;
    }
  }

  void _showGameResult(int reward) {
    final accuracy = _game.getAccuracy();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'Reward Claimed!',
        emoji: '💰',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox(context, 'Moves', '${_game.moves}'),
                _buildStatBox(
                  context,
                  'Accuracy',
                  '${accuracy.toStringAsFixed(1)}%',
                  color: accuracy >= 80 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              '${(reward * 1000).toInt()} Coins added to wallet!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _resetGame() {
    setState(() {
      _game = _gameService.createMemoryMatchGame();
      _selectedIndex1 = null;
      _selectedIndex2 = null;
      _isProcessing = false;
      _isPreviewMode = true;
      _isGameCompleted = false;
    });

    Future.delayed(Duration(seconds: _previewSeconds), () {
      if (mounted) {
        setState(() {
          _isPreviewMode = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text('Memory Match'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                children: [
                  // Game Info Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isPreviewMode)
                          Expanded(
                            child: Center(
                              child: Text(
                                'Memorize! Cards flip in $_previewSeconds...',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          )
                        else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moves',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_game.moves}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Matched',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_game.matchedPairs}/4',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Reward',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '500+ Coins',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Game Board (3x3)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(9, (index) {
                        final isCenter = index == 4;
                        final isRevealed =
                            _game.revealed[index] || _isPreviewMode;
                        final isMatched = _game.matched[index];
                        final card = _game.cards[index];
                        final isSelected =
                            _selectedIndex1 == index ||
                            _selectedIndex2 == index;

                        if (isCenter) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                              border: Border.all(
                                color: AppTheme.surfaceVariant,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.gamepad,
                                color: AppTheme.primaryColor,
                                size: 32,
                              ),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: _isProcessing || isMatched || _isPreviewMode
                              ? null
                              : () => _handleCardTap(index),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _matchAnimation,
                              _matchPulseAnimation,
                            ]),
                            builder: (context, child) {
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(
                                    (isRevealed || isMatched ? 0 : 1) *
                                        (isSelected
                                            ? _matchAnimation.value * 3.14159
                                            : 0),
                                  ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isRevealed || isMatched
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS,
                                    ),
                                    border: Border.all(
                                      color: isMatched
                                          ? Colors.green
                                          : isSelected
                                          ? AppTheme.primaryColor.withValues(
                                              alpha: 0.8,
                                            )
                                          : AppTheme.surfaceVariant,
                                      width: isMatched
                                          ? 3
                                          : (isSelected ? 2 : 1),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : AppTheme.cardShadow,
                                  ),
                                  child: Center(
                                    child: AnimatedScale(
                                      scale: (isRevealed || isMatched)
                                          ? 1.0
                                          : 0.5,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: AnimatedOpacity(
                                        opacity: isRevealed || isMatched
                                            ? 1.0
                                            : 0.0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Text(
                                          card,
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Progress Bar
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              '${(_game.matchedPairs / 4 * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _game.matchedPairs / 4,
                            minHeight: 8,
                            backgroundColor: AppTheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetGame,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Game'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Exit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Cooldown Info
                  Consumer<CooldownService>(
                    builder: (context, cooldownService, _) {
                      final remaining = cooldownService.getRemainingCooldown(
                        userProvider.user.userId,
                        'game_memory',
                      );

                      if (remaining > 0) {
                        return Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.orange),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cooldown Active',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Next game in ${cooldownService.formatCooldown(remaining)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // How to Play
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 How to Play',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          '• Cards are hidden, tap to reveal\n'
                          '• Match pairs of identical emojis\n'
                          '• Complete all 4 pairs to win\n'
                          '• Watch ad to claim reward\n'
                          '• 90%+ accuracy: 750 Coins | 70%+: 600 Coins | Base: 500 Coins',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
