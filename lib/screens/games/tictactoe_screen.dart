import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/cooldown_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../services/local_notification_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/custom_dialog.dart';

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
            Text('• Win to earn ₹0.08'),
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
          await _recordGameWin();
          if (mounted) {
            // Optimistic update
            userProvider.updateLocalState(
              availableBalance: userProvider.user.availableBalance + 0.08,
              totalEarnings: userProvider.user.totalEarnings + 0.08,
              gamesPlayedToday: userProvider.user.gamesPlayedToday + 1,
            );

            _showGameResult(
              title: 'You Won! 🎉',
              message: 'You earned ₹0.08',
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

  Future<void> _recordGameWin() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          StateSnackbar.showError(context, 'User not logged in');
        }
        return;
      }

      // Get providers before async gap
      final dedup = Provider.of<RequestDeduplicationService>(
        context,
        listen: false,
      );
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );
      final firestore = FirestoreService();

      // Check backend health
      final cloudflareService = CloudflareWorkersService();
      final isBackendHealthy = await cloudflareService.healthCheck();
      if (!isBackendHealthy) {
        if (mounted) {
          StateSnackbar.showError(
            context,
            'Cannot connect to server. Game result not saved.',
          );
        }
        return;
      }

      // Get device fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // Generate unique request ID for deduplication
      final requestId = dedup.generateRequestId(user.uid, 'game_result', {
        'gameId': 'tictactoe',
        'won': true,
        'reward': 0.50,
      });

      // Check if already processed (prevents duplicate earnings)
      final cachedRecord = dedup.getFromLocalCache(requestId);
      if (cachedRecord != null && cachedRecord.success) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Game result already recorded');
        }
        return;
      }

      // Record game result via Firestore with deduplication fields
      await firestore.recordGameResult(
        user.uid,
        'tictactoe',
        true,
        0.08,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Mark as processed in deduplication cache
      await dedup.recordRequest(
        requestId: requestId,
        requestHash: requestId.hashCode.toString(),
        success: true,
        transactionId: 'game:${DateTime.now().millisecondsSinceEpoch}',
      );

      // Set cooldown
      _cooldownService.startCooldown(user.uid, 'game_tictactoe', 300);

      // Schedule notification
      LocalNotificationService().scheduleCooldownExpiry(
        gameName: 'Tic-Tac-Toe',
        duration: const Duration(seconds: 300),
      );

      debugPrint('✅ Game win recorded for ${user.uid}: tictactoe');

      // Check for Ad Break
      if (mounted) {
        await _adService.checkAdBreak();
      }
    } catch (e) {
      debugPrint('Error recording game: $e');
      if (mounted) {
        StateSnackbar.showError(context, 'Failed to record game result');
      }
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
              won ? '₹0.08 earned!' : 'Better luck next time!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: won ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (won)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Watch ad for +₹0.10 bonus?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (won)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _watchBonusAd();
              },
              child: const Text('Watch Ad'),
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

  // Watch rewarded ad for bonus +₹0.10
  Future<void> _watchBonusAd() async {
    await _adService.showRewardedAd(
      onRewardEarned: (reward) async {
        try {
          final user = fb_auth.FirebaseAuth.instance.currentUser;
          if (user == null) return;

          // Add bonus to user balance
          // Balance update handled by recordGameResult via backend

          if (mounted) {
            StateSnackbar.showSuccess(context, 'Bonus ₹0.10 added!');
          }
        } catch (e) {
          debugPrint('Error adding bonus: $e');
        }
      },
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
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text('Tic Tac Toe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHowToPlay,
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
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
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
                                        '₹0.08',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.green,
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
                                    onTap: isEmpty
                                        ? () => _handleTap(index)
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isEmpty
                                            ? AppTheme.surfaceVariant
                                            : AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          cell,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(target: isEmpty ? 0 : 1)
                                  .scale(
                                    duration: 300.ms,
                                    curve: Curves.easeOutBack,
                                  )
                                  .fade();
                            }),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space32),

                        // Game Status
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              if (!_game.isGameOver)
                                Column(
                                  children: [
                                    Text(
                                      'Your turn - Tap to make a move',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: AppTheme.space12),
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
                                            ? Colors.green
                                            : Colors.orange,
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
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(color: Colors.orange),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusS,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          color: Colors.orange,
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
