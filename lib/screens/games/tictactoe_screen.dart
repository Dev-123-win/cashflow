import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/cooldown_service.dart';
import '../../services/ad_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/cloudflare_workers_service.dart';
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
  late final CooldownService _cooldownService;
  late final AdService _adService;
  late TicTacToeGame _game;
  bool _isProcessing = false;
  bool _adShownPreGame = false;
  bool _isGameCompleted = false;
  double _difficulty = 0.3; // Start easy

  // Idempotency and Race Condition Handling
  String? _currentRequestId;
  Future<void>? _claimFuture;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _cooldownService = CooldownService();
    _adService = AdService();
    _initializeGame();
    _showPreGameAd();
  }

  void _initializeGame() {
    _game = _gameService.createTicTacToeGame();
    _game.setDifficulty(_difficulty);
    _isGameCompleted = false;
    _currentRequestId = null; // Reset request ID for new game
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

    // Check cooldown
    final remaining = _cooldownService.getRemainingCooldown(
      user.userId,
      'game_tictactoe',
    );
    if (remaining > 0) {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'Next game available in ${_cooldownService.formatCooldown(remaining)}',
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
    try {
      // Show Rewarded Ad
      await _adService.showRewardedAd(
        onRewardEarned: (rewardItem) async {
          if (!mounted) return;

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );

          // 1. Optimistic Update
          userProvider.addOptimisticCoins(60);

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
            // 3. Rollback on failure
            userProvider.rollbackOptimisticCoins(60);
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

      // Call Backend API
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
          userProvider.updateLocalState(coins: newBalance);
          userProvider.confirmOptimisticCoins(80);
        }

        // Update Cooldown locally
        _cooldownService.startCooldown(user.uid, 'game_tictactoe', 300);

        debugPrint('✅ Game win recorded: ${result['transaction']['id']}');
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
            const SizedBox(height: AppTheme.space16),
            Text(
              won ? 'Watch Ad to Claim 60 Coins' : 'Better luck next time!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: won ? AppTheme.successColor : AppTheme.warningColor,
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
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
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
                    padding: const EdgeInsets.all(AppTheme.space16),
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '60 Coins',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: AppTheme.successColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'vs',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'AI (O)',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Win Reward',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space32),

                        // Game Board
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
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
                              final cell = _game.board[index];
                              final isEmpty = cell.isEmpty;

                              return GestureDetector(
                                onTap: isEmpty ? () => _handleTap(index) : null,
                                child:
                                    Container(
                                          decoration: BoxDecoration(
                                            color: isEmpty
                                                ? AppTheme.surfaceVariant
                                                : AppTheme.backgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.1),
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
                                                    ? AppTheme.primaryColor
                                                    : AppTheme.secondaryColor,
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
                        const SizedBox(height: AppTheme.space32),

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
                                        backgroundColor:
                                            AppTheme.surfaceVariant,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppTheme.primaryColor,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _game.playerWon()
                                            ? AppTheme.successColor
                                            : AppTheme.warningColor,
                                      ),
                                ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
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
                                onPressed: _game.isGameOver ? _resetGame : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('New Game'),
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

                        // Cooldown Info (if on cooldown)
                        Consumer<CooldownService>(
                          builder: (context, cooldownService, _) {
                            final remaining = cooldownService
                                .getRemainingCooldown(
                                  userProvider.user.userId,
                                  'game_tictactoe',
                                );

                            if (remaining > 0) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppTheme.space12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.warningColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusS,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          color: AppTheme.warningColor,
                                        ),
                                        const SizedBox(width: AppTheme.space12),
                                        Expanded(
                                          child: Text(
                                            'Next game available in ${cooldownService.formatCooldown(remaining)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
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
