import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/game_service.dart';
import '../../services/ad_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/transaction_service.dart'; // For local history
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/error_states.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late final GameService _gameService;
  late final AdService _adService;
  late TicTacToeGame _game;
  bool _isProcessing = false;
  bool _adShownPreGame = false;
  bool _isGameCompleted = false;
  double _difficulty = 0.3; // Start easy

  // Idempotency and Race Condition Handling
  String? _currentRequestId;
  Future<void>? _claimFuture;
  bool _rewardClaimed = false; // ✅ BUG FIX: Prevent duplicate reward claims

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _adService = AdService();
    _initializeGame();
    _showPreGameAd();
  }

  void _initializeGame() {
    _game = _gameService.createTicTacToeGame();
    _game.setDifficulty(_difficulty);
    _isGameCompleted = false;
    _currentRequestId = null; // Reset request ID for new game
    _rewardClaimed = false; // ✅ BUG FIX: Reset reward claim flag
  }

  // Show pre-game interstitial ad with 40% probability
  Future<void> _showPreGameAd() async {
    if (_adShownPreGame) return;

    // 40% chance to show ad
    if (math.Random().nextDouble() < 0.4) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _adService.showInterstitialAd();
      }
    }
    _adShownPreGame = true;
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'How to Play',
        emoji: '❓',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Mark your position with X'),
            SizedBox(height: 8),
            Text('• AI will respond with O'),
            SizedBox(height: 8),
            Text('• Get 3 in a row to win'),
            SizedBox(height: 8),
            Text('• Win to earn 60 Coins'),
            SizedBox(height: 8),
            Text('• Max 20 games per day'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(int index) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    // Check Daily Limit
    if (user.gamesPlayedToday >= 20) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Daily game limit reached (20/20). Come back tomorrow!',
        );
      }
      return;
    }

    if (_isProcessing ||
        _game.isGameOver ||
        _game.board[index].isNotEmpty ||
        _isGameCompleted) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _game.playerMove(index);

      if (_game.isGameOver) {
        _isGameCompleted = true;
        // Game ended
        if (_game.playerWon()) {
          // Generate Request ID ONCE for this win to ensure idempotency
          _currentRequestId =
              'tictactoe_${DateTime.now().millisecondsSinceEpoch}';

          // Don't record win yet - wait for ad claim
          if (mounted) {
            _showGameResult(
              title: 'You Won! 🎉',
              message: 'Claim your 60 Coins!',
              won: true,
            );

            // Increase difficulty for next game
            setState(() {
              _difficulty = (_difficulty + 0.1).clamp(0.0, 0.9);
            });
          }
        } else if (_game.winner == 'draw') {
          if (mounted) {
            _showGameResult(
              title: 'Draw Game!',
              message: 'No winner this time',
              won: false,
            );
          }
        } else {
          if (mounted) {
            _showGameResult(
              title: 'AI Won',
              message: 'Try again next time',
              won: false,
            );
          }
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _claimReward() async {
    if (_claimFuture != null) return;

    _claimFuture = _executeClaimReward();
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

  Future<void> _executeClaimReward() async {
    // ✅ BUG FIX: Prevent multiple reward claims (fixes 4x multiplication)
    if (_rewardClaimed) {
      debugPrint('⚠️ Reward already claimed, ignoring duplicate callback');
      return;
    }
    _rewardClaimed = true;

    try {
      // Show Rewarded Ad
      await _adService.showRewardedAd(
        onRewardEarned: (rewardItem) async {
          if (!mounted) return;

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );

          // Use the request ID as transaction ID for tracking
          final transactionId =
              _currentRequestId ??
              'tictactoe_${DateTime.now().millisecondsSinceEpoch}';

          // 1. Optimistic Update with transaction tracking
          userProvider.addOptimisticCoins(60, transactionId, 'game');

          // 2. Call Backend with Timeout
          try {
            await _recordGameWin().timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception('Request timed out');
              },
            );

            // Success handled in _recordGameWin
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
      debugPrint('Error in claim reward: $e');
    }
  }

  Future<void> _recordGameWin() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );

      // Use Cloudflare Service
      final cloudflareService = CloudflareWorkersService();

      // Get device fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // Use the ID generated when game ended, or fallback (shouldn't happen)
      final requestId =
          _currentRequestId ??
          'tictactoe_${DateTime.now().millisecondsSinceEpoch}';

      // ✅ BUG FIX: Record local transaction FIRST (fixes missing history)
      // Local history should show ALL games, regardless of backend success
      await TransactionService().recordTransaction(
        userId: user.uid,
        type: 'earning',
        amount: 60.0,
        gameType: 'tictactoe',
        success: true,
        status: 'completed',
        description: 'Tic-Tac-Toe Win',
        extraData: {'requestId': requestId},
      );
      debugPrint('✅ Game transaction recorded locally');

      // THEN call Backend API (can fail safely)
      try {
        final result = await cloudflareService.recordGameResult(
          userId: user.uid,
          gameId: 'tictactoe',
          won: true,
          score: 0,
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
                'tictactoe_${DateTime.now().millisecondsSinceEpoch}';
            userProvider.confirmOptimisticCoins(transactionId, newBalance);
          }

          debugPrint('✅ Backend confirmed game win');
        }
      } catch (e) {
        // Backend failure doesn't affect local history
        debugPrint('⚠️ Backend call failed: $e');
        rethrow; // Still throw to trigger rollback
      }
    } catch (e) {
      debugPrint('Error recording game: $e');
      rethrow;
    }
  }

  void _showGameResult({
    required String title,
    required String message,
    required bool won,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: title,
        emoji: won ? '🎉' : '🤝',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppDimensions.space16),
            Text(
              won ? 'Watch Ad to Claim 60 Coins' : 'Better luck next time!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: won ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (won)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _claimReward();
              },
              child: const Text('Claim Reward 📺'),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Tic Tac Toe'),
          leading: ScaleButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back),
          ),
          actions: [
            ScaleButton(
              onTap: _showHowToPlay,
              child: const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(Icons.help_outline),
              ),
            ),
          ],
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      children: [
                        // Game Info Card
                        ZenCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You (X)',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '60 Coins',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text('vs', style: theme.textTheme.titleLarge),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'AI (O)',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Win Reward',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space32),

                        // Game Board
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
                              final cell = _game.board[index];
                              final isEmpty = cell.isEmpty;

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: isEmpty ? () => _handleTap(index) : null,
                                child:
                                    Container(
                                          decoration: BoxDecoration(
                                            color: isEmpty
                                                ? surfaceVariant
                                                : theme.scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cell,
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: cell == 'X'
                                                    ? primaryColor
                                                    : secondaryColor,
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate(target: isEmpty ? 0 : 1)
                                        .scale(
                                          duration: 300.ms,
                                          curve: Curves.easeOutBack,
                                        )
                                        .fade(),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space32),

                        // Game Status
                        ZenCard(
                          child: Column(
                            children: [
                              if (!_game.isGameOver)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 4,
                                      child: LinearProgressIndicator(
                                        backgroundColor: surfaceVariant,
                                        valueColor: AlwaysStoppedAnimation(
                                          primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  _game.playerWon()
                                      ? 'You Won! 🎉'
                                      : _game.winner == 'draw'
                                      ? 'Draw Game!'
                                      : 'AI Won 🤖',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _game.playerWon()
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
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
                                onPressed: _game.isGameOver ? _resetGame : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('New Game'),
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
                      ],
                    ),
                  ),
                ),
                // Banner Ad at the bottom
                const BannerAdWidget(),
              ],
            );
          },
        ),
      ),
    );
  }
}
