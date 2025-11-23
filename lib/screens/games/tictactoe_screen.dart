import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/cooldown_service.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late final GameService _gameService;
  late final CooldownService _cooldownService;
  late TicTacToeGame _game;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _cooldownService = CooldownService();
    _initializeGame();
  }

  void _initializeGame() {
    _game = _gameService.createTicTacToeGame();
  }

  Future<void> _handleTap(int index) async {
    if (_isProcessing || _game.isGameOver || _game.board[index].isNotEmpty) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _game.playerMove(index);

      if (_game.isGameOver) {
        // Game ended
        if (_game.playerWon()) {
          await _recordGameWin();
          if (mounted) {
            _showGameResult(
              title: 'You Won! 🎉',
              message: 'You earned ₹0.50',
              won: true,
            );
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
      setState(() => _isProcessing = false);
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

      // Get deduplication and fingerprinting services
      final dedup = Provider.of<RequestDeduplicationService>(
        context,
        listen: false,
      );
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );
      final firestore = FirestoreService();

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
        0.50,
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

      debugPrint('✅ Game win recorded for ${user.uid}: tictactoe');
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppTheme.space16),
            Text(
              won ? '₹0.50 earned!' : 'Better luck next time!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: won ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
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
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text('Tic Tac Toe'),
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You (X)',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹0.50',
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'AI (O)',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Win Reward',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                        final cell = _game.board[index];
                        final isEmpty = cell.isEmpty;

                        return GestureDetector(
                          onTap: isEmpty && !_game.isGameOver && !_isProcessing
                              ? () => _handleTap(index)
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEmpty
                                  ? AppTheme.backgroundColor
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                              border: Border.all(
                                color: AppTheme.surfaceVariant,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cell,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: cell == 'X'
                                      ? Colors.blue
                                      : cell == 'O'
                                      ? Colors.red
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Game Status
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        if (!_game.isGameOver)
                          Column(
                            children: [
                              Text(
                                'Your turn - Tap to make a move',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: AppTheme.space12),
                              SizedBox(
                                height: 4,
                                child: LinearProgressIndicator(
                                  backgroundColor: AppTheme.surfaceVariant,
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
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _game.playerWon()
                                      ? Colors.green
                                      : Colors.orange,
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
                      final remaining = cooldownService.getRemainingCooldown(
                        userProvider.user.userId,
                        'game_tictactoe',
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
                                      'Next game available in ${cooldownService.formatCooldown(remaining)}',
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
                          '• You play as X, AI plays as O\n'
                          '• Tap any empty cell to place your mark\n'
                          '• Get 3 in a row (horizontal, vertical, diagonal) to win\n'
                          '• Win: ₹0.50 | You can play once every 5 minutes',
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
