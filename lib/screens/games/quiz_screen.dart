import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/quiz_service.dart';
import '../../services/ad_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/error_states.dart';

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

    // Optimistic Update
    userProvider.addOptimisticCoins(reward);

    try {
      // Record result to backend with timeout
      await _quizService
          .recordQuizResult(
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
      // Rollback
      userProvider.rollbackOptimisticCoins(reward);
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
              backgroundColor: (passed ? AppTheme.successColor : Colors.orange)
                  .withValues(alpha: 0.2),
              child: Text(
                '${(correct / total * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: passed ? AppTheme.successColor : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              '$correct/$total Correct',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space12),
            if (passed)
              Text(
                'Watch Ad to claim 50 Coins!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Get at least 3 correct to earn rewards.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text('Quiz'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space32),
          Container(
            padding: const EdgeInsets.all(AppTheme.space32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text('🧠', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppTheme.space24),
                Text(
                  'Unlimited Quiz',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'Answer 5 questions correctly to earn 50 Coins!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space32),
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
                  '📋 How It Works',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  '• You have 60 seconds for 5 questions\n'
                  '• Get 3+ correct to win\n'
                  '• Watch an ad to claim 50 Coins\n'
                  '• Play as many times as you want!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.space16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    final isAnswered = _answers[_currentQuestionIndex] != null;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        children: [
          // Progress
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
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      '${_timeRemaining}s',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _timeRemaining <= 10
                            ? Colors.red
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Question
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  question.category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Options
          ...List.generate(question.options.length, (index) {
            final isSelected = _answers[_currentQuestionIndex] == index;

            return GestureDetector(
              onTap: () => _selectAnswer(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.space12),
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.backgroundColor,
                        border: Border.all(color: AppTheme.surfaceVariant),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppTheme.space32),

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
              const SizedBox(width: AppTheme.space16),
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
