import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/cooldown_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen>
    with TickerProviderStateMixin {
  late final GameService _gameService;
  late final CooldownService _cooldownService;
  late MemoryMatchGame _game;
  int? _selectedIndex1;
  int? _selectedIndex2;
  bool _isProcessing = false;
  late AnimationController _matchAnimation;
  late AnimationController _matchPulseAnimation;
  late AnimationController _successAnimation;
  bool _isPreviewMode = true;
  int _previewSeconds = 3;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _cooldownService = CooldownService();
    _game = _gameService.createMemoryMatchGame();

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
    if (_isProcessing ||
        _game.revealed[index] ||
        _game.matched[index] ||
        _selectedIndex1 == index) {
      return;
    }

    setState(() {
      if (_selectedIndex1 == null) {
        _selectedIndex1 = index;
        _game.revealCard(index);
      } else {
        _selectedIndex2 = index;
        _game.revealCard(index);
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
          await _recordGameWin();
          if (mounted) {
            _showGameResult();
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _game.resetCards(_selectedIndex1!, _selectedIndex2!);
      }

      setState(() {
        _selectedIndex1 = null;
        _selectedIndex2 = null;
        _isProcessing = false;
      });
    }
  }

  Future<void> _recordGameWin() async {
    try {
      final userProvider = context.read<UserProvider>();

      // Check backend health
      final cloudflareService = CloudflareWorkersService();
      final isBackendHealthy = await cloudflareService.healthCheck();
      if (!isBackendHealthy) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => CustomDialog(
              title: 'Connection Error',
              emoji: '⚠️',
              content: const Text(
                'Cannot connect to server. Game result not saved.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final accuracy = _game.getAccuracy();

      // Reward based on accuracy: 90%+ = ₹0.75, 70%+ = ₹0.60, else = ₹0.50
      double reward = 0.50;
      if (accuracy >= 90) {
        reward = 0.75;
      } else if (accuracy >= 70) {
        reward = 0.60;
      }

      await _gameService.recordGameWin(
        userProvider.user.userId,
        'memory_match',
        customReward: reward,
      );

      _cooldownService.startCooldown(
        userProvider.user.userId,
        'game_memory',
        300,
      );
    } catch (e) {
      debugPrint('Error recording game: $e');
    }
  }

  void _showGameResult() {
    final accuracy = _game.getAccuracy();
    double reward = 0.50;
    if (accuracy >= 90) {
      reward = 0.75;
    } else if (accuracy >= 70) {
      reward = 0.60;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'Game Complete!',
        emoji: '🎉',
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
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '₹${reward.toStringAsFixed(2)} earned!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
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
                                '${_game.matchedPairs}/6',
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
                                '₹0.50+',
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

                  // Game Board
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(12, (index) {
                        final isRevealed =
                            _game.revealed[index] || _isPreviewMode;
                        final isMatched = _game.matched[index];
                        final card = _game.cards[index];
                        final isSelected =
                            _selectedIndex1 == index ||
                            _selectedIndex2 == index;

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
                              '${(_game.matchedPairs / 6 * 100).toStringAsFixed(0)}%',
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
                            value: _game.matchedPairs / 6,
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
                          '• Complete all 6 pairs to win\n'
                          '• Better accuracy = Higher reward!\n'
                          '• 90%+ accuracy: ₹0.75 | 70%+: ₹0.60 | Base: ₹0.50',
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
