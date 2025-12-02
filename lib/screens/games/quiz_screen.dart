import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/quiz_service.dart';
import '../../services/ad_service.dart';
import '../../services/transaction_service.dart'; // For local history
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/error_states.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizService _quizService;
  late final AdService _adService;
  late List<QuizQuestion> _questions;
  late List<int?> _answers;
  int _currentQuestionIndex = 0;
  bool _quizStarted = false;
  bool _quizCompleted = false;
  int _timeRemaining = 60;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _adService = AdService();
    _initializeQuiz();
    _adService.loadRewardedAd();
  }

  void _initializeQuiz() {
    _questions = _quizService.getRandomQuestions();
    _answers = List.filled(_questions.length, null);
  }

  void _startQuiz() {
    setState(() => _quizStarted = true);
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _quizStarted && !_quizCompleted) {
        setState(() {
          _timeRemaining--;
        });
        if (_timeRemaining <= 0) {
          _completeQuiz();
          return false;
        }
        return true;
      }
      return false;
    });
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _completeQuiz() async {
    setState(() => _quizCompleted = true);
    final score = _quizService.calculateScore(_questions, _answers);

    if (mounted) {
      _showResultDialog(score);
    }
  }

  Future<void> _watchAdToClaim(Map<String, dynamic> score) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);
    Navigator.pop(context); // Close result dialog

    try {
      final success = await _adService.showRewardedAd(
        onRewardEarned: (amount) async {
          await _claimReward(score);
        },
      );

      if (!success) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Ad not ready. Please try again.');
          _showResultDialog(score); // Re-show dialog
        }
      }
    } catch (e) {
      debugPrint('Error showing ad: $e');
      if (mounted) {
        _showResultDialog(score);
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  Future<void> _claimReward(Map<String, dynamic> score) async {
    final userProvider = context.read<UserProvider>();
    final reward = 50; // Fixed 50 Coins for Quiz

    // Generate unique transaction ID for tracking
    final transactionId = 'quiz_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic Update with transaction tracking
    userProvider.addOptimisticCoins(reward, transactionId, 'quiz');

    try {
      // Record result to backend with timeout
      await _quizService
          .recordQuizResult(
            context,
            userProvider.user.userId,
            score['correct'],
            score['total'],
            reward,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      // ✅ Record transaction locally for history screen
      await TransactionService().recordTransaction(
        userId: userProvider.user.userId,
        type: 'earning',
        amount: reward.toDouble(),
        gameType: 'quiz',
        success: true,
        status: 'completed',
        description: 'Quiz Reward',
        extraData: {'requestId': transactionId},
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: 'Reward Claimed!',
            emoji: '🎉',
            content: Text(
              'You earned $reward Coins!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetQuiz();
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      // Rollback using transaction ID
      userProvider.rollbackOptimisticCoins(transactionId);
      if (mounted) {
        StateSnackbar.showError(
          context,
          'Failed to claim reward: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> score) {
    final correct = score['correct'] as int;
    final total = score['total'] as int;
    final passed = correct >= 3; // Pass if 3 or more correct

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: passed ? 'Quiz Completed!' : 'Try Again',
        emoji: passed ? '🏆' : '📚',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: (passed ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.2),
              child: Text(
                '${(correct / total * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: passed ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              '$correct/$total Correct',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.space12),
            if (passed)
              Text(
                'Watch Ad to claim 50 Coins!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Get at least 3 correct to earn rewards.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          if (passed)
            ElevatedButton(
              onPressed: _isClaiming ? null : () => _watchAdToClaim(score),
              child: _isClaiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Watch Ad to Claim'),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetQuiz();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _quizStarted = false;
      _quizCompleted = false;
      _timeRemaining = 60;
      _initializeQuiz();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Quiz'),
          leading: ScaleButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (!_quizStarted) {
              return _buildStartScreen();
            } else if (_quizCompleted) {
              return const SizedBox.shrink();
            } else {
              return _buildQuizScreen();
            }
          },
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.space32),
          ZenCard(
            child: Column(
              children: [
                Text('🧠', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppDimensions.space24),
                Text(
                  'Unlimited Quiz',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Answer 5 questions correctly to earn 50 Coins!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space32),
          ZenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 How It Works', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  '• You have 60 seconds for 5 questions\n'
                  '• Get 3+ correct to win\n'
                  '• Watch an ad to claim 50 Coins\n'
                  '• Play as many times as you want!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppDimensions.space16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    final question = _questions[_currentQuestionIndex];
    final isAnswered = _answers[_currentQuestionIndex] != null;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        children: [
          // Progress
          ZenCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      '${_timeRemaining}s',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _timeRemaining <= 10
                            ? AppColors.error
                            : textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),

          // Question
          ZenCard(
            child: Column(
              children: [
                Text(
                  question.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  question.category,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),

          // Options
          ...List.generate(question.options.length, (index) {
            final isSelected = _answers[_currentQuestionIndex] == index;

            return ScaleButton(
              onTap: () => _selectAnswer(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.2)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: isSelected ? primaryColor : surfaceVariant,
                    width: isSelected ? 2 : 1,
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
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? primaryColor
                            : theme.scaffoldBackgroundColor,
                        border: Border.all(color: surfaceVariant),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space16),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: primaryColor),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppDimensions.space32),

          // Navigation Buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAnswered ? _nextQuestion : null,
                  icon: Icon(
                    _currentQuestionIndex == _questions.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Submit'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
