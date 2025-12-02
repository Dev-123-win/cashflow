import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/game_service.dart';

import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/transaction_service.dart'; // For local history
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/error_states.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen>
    with TickerProviderStateMixin {
  late final GameService _gameService;

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

  // Idempotency
  String? _currentRequestId;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();

    _adService = AdService();
    _game = _gameService.createMemoryMatchGame();
    _isGameCompleted = false;
    _currentRequestId = null;

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
          // Generate Request ID ONCE for this win
          _currentRequestId = 'memory_${DateTime.now().millisecondsSinceEpoch}';

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
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Claim Reward 📺',
                    style: TextStyle(
                      color: AppColors.success,
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

  Future<void>? _claimFuture;

  Future<void> _watchAdToClaim() async {
    if (_claimFuture != null) return;

    _claimFuture = _executeWatchAdToClaim();
    try {
      await _claimFuture;
    } finally {
      if (mounted) {
        setState(() {
          _claimFuture = null;
        });
      }
    }
  }

  Future<void> _executeWatchAdToClaim() async {
    try {
      await _adService.showRewardedAd(
        onRewardEarned: (rewardItem) async {
          if (!mounted) return;

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final accuracy = _game.getAccuracy();

          // Fixed reward (matches backend)
          int reward = 50; // 50 Coins

          // Use request ID as transaction ID for tracking
          final transactionId =
              _currentRequestId ??
              'memory_${DateTime.now().millisecondsSinceEpoch}';

          // 1. Optimistic Update with transaction tracking
          userProvider.addOptimisticCoins(reward, transactionId, 'game');

          // Show success dialog immediately
          if (mounted) {
            _showGameResult(reward);
          }

          // 2. Call Backend with Timeout
          try {
            await _recordGameWin(reward, accuracy.toInt()).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception('Request timed out');
              },
            );
          } catch (e) {
            // 3. Rollback on failure using transaction ID
            userProvider.rollbackOptimisticCoins(transactionId);
            if (mounted) {
              StateSnackbar.showError(
                context,
                'Failed to save reward: ${e.toString().replaceAll('Exception: ', '')}',
              );
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error in watch ad to claim: $e');
    }
  }

  Future<void> _recordGameWin(int estimatedReward, int accuracy) async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );

      // Check backend health
      final cloudflareService = CloudflareWorkersService();

      // Get device fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // Use Idempotent Request ID
      final requestId =
          _currentRequestId ??
          'memory_${DateTime.now().millisecondsSinceEpoch}';

      final result = await cloudflareService.recordGameResult(
        userId: user.uid,
        gameId: 'memory_match',
        won: true,
        score: accuracy, // Pass accuracy as score
        deviceId: deviceFingerprint,
        requestId: requestId,
      );

      // Update Local State from Backend Response
      if (result['success'] == true) {
        final newBalance = result['newBalance'];
        if (newBalance != null) {
          // Confirm optimistic update with server balance
          final transactionId =
              _currentRequestId ??
              'memory_${DateTime.now().millisecondsSinceEpoch}';
          userProvider.confirmOptimisticCoins(transactionId, newBalance);
        }

        // ✅ Record transaction locally for history screen
        final actualReward = result['reward'] ?? estimatedReward;
        await TransactionService().recordTransaction(
          userId: user.uid,
          type: 'earning',
          amount: actualReward.toDouble(),
          gameType: 'memory_match',
          success: true,
          status: 'completed',
          description: 'Memory Match Win',
          extraData: {'requestId': requestId},
        );

        debugPrint('✅ Game win recorded: ${result['transaction']['id']}');
      }
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
                  color: accuracy >= 80 ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              '${(reward).toInt()} Coins added to wallet!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
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
      _currentRequestId = null;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Memory Match'),
          leading: ScaleButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                children: [
                  // Game Info Card
                  ZenCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isPreviewMode)
                          Expanded(
                            child: Center(
                              child: Text(
                                'Memorize! Cards flip in $_previewSeconds...',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Moves', style: theme.textTheme.labelSmall),
                              const SizedBox(height: 4),
                              Text(
                                '${_game.moves}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Matched',
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_game.matchedPairs}/4',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Reward', style: theme.textTheme.labelSmall),
                              const SizedBox(height: 4),
                              Text(
                                '50 Coins',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Game Board (3x3)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusS,
                              ),
                              border: Border.all(color: surfaceVariant),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.gamepad,
                                color: primaryColor,
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
                                        : primaryColor,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusS,
                                    ),
                                    border: Border.all(
                                      color: isMatched
                                          ? AppColors.success
                                          : isSelected
                                          ? primaryColor.withValues(alpha: 0.8)
                                          : surfaceVariant,
                                      width: isMatched
                                          ? 3
                                          : (isSelected ? 2 : 1),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.3 : 0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
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
                  const SizedBox(height: AppDimensions.space32),

                  // Progress Bar
                  ZenCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress', style: theme.textTheme.labelLarge),
                            Text(
                              '${(_game.matchedPairs / 4 * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _game.matchedPairs / 4,
                            minHeight: 8,
                            backgroundColor: surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

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
                      const SizedBox(width: AppDimensions.space16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Exit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  const SizedBox(height: AppDimensions.space32),

                  // How to Play
                  ZenCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 How to Play',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        Text(
                          '• Cards are hidden, tap to reveal\n'
                          '• Match pairs of identical emojis\n'
                          '• Complete all 4 pairs to win\n'
                          '• Watch ad to claim reward\n'
                          '• Win reward: 50 Coins',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: textSecondary,
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
