import 'package:flutter/material.dart';
import 'firestore_service.dart';

/// Quiz question model (Top-level class)
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String category;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.category,
  });
}

/// Quiz Service for managing quiz game logic
class QuizService {
  static final QuizService _instance = QuizService._internal();

  factory QuizService() {
    return _instance;
  }

  QuizService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Quiz configuration
  static const int questionsPerQuiz = 5;
  static const double rewardPerCorrect = 0.15;
  static const int timeLimitSeconds = 60;

  /// Question bank - Simple Math Questions for Beginners Only
  final List<QuizQuestion> _questionBank = [
    // Basic Addition
    QuizQuestion(
      id: 'q1',
      question: 'What is 5 + 3?',
      options: ['7', '8', '9', '10'],
      correctAnswerIndex: 1,
      category: 'Addition',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'What is 12 + 8?',
      options: ['18', '19', '20', '21'],
      correctAnswerIndex: 2,
      category: 'Addition',
    ),
    QuizQuestion(
      id: 'q3',
      question: 'What is 6 + 7?',
      options: ['12', '13', '14', '15'],
      correctAnswerIndex: 1,
      category: 'Addition',
    ),
    // Basic Subtraction
    QuizQuestion(
      id: 'q4',
      question: 'What is 10 - 3?',
      options: ['5', '6', '7', '8'],
      correctAnswerIndex: 2,
      category: 'Subtraction',
    ),
    QuizQuestion(
      id: 'q5',
      question: 'What is 20 - 7?',
      options: ['12', '13', '14', '15'],
      correctAnswerIndex: 1,
      category: 'Subtraction',
    ),
    QuizQuestion(
      id: 'q6',
      question: 'What is 15 - 6?',
      options: ['8', '9', '10', '11'],
      correctAnswerIndex: 1,
      category: 'Subtraction',
    ),
    // Simple Multiplication
    QuizQuestion(
      id: 'q7',
      question: 'What is 4 × 5?',
      options: ['18', '19', '20', '21'],
      correctAnswerIndex: 2,
      category: 'Multiplication',
    ),
    QuizQuestion(
      id: 'q8',
      question: 'What is 3 × 7?',
      options: ['20', '21', '22', '23'],
      correctAnswerIndex: 1,
      category: 'Multiplication',
    ),
    QuizQuestion(
      id: 'q9',
      question: 'What is 6 × 6?',
      options: ['34', '35', '36', '37'],
      correctAnswerIndex: 2,
      category: 'Multiplication',
    ),
    QuizQuestion(
      id: 'q10',
      question: 'What is 9 + 11?',
      options: ['18', '19', '20', '21'],
      correctAnswerIndex: 2,
      category: 'Addition',
    ),
  ];

  /// Get random quiz questions
  List<QuizQuestion> getRandomQuestions({int count = questionsPerQuiz}) {
    final shuffled = List.of(_questionBank)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Check if answer is correct
  bool isCorreectAnswer(QuizQuestion question, int selectedIndex) {
    return selectedIndex == question.correctAnswerIndex;
  }

  /// Calculate score
  Map<String, dynamic> calculateScore(
    List<QuizQuestion> questions,
    List<int?> answers,
  ) {
    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] != null && isCorreectAnswer(questions[i], answers[i]!)) {
        correct++;
      }
    }

    double percentage = (correct / questions.length) * 100;
    double reward = correct * rewardPerCorrect;

    return {
      'correct': correct,
      'total': questions.length,
      'percentage': percentage,
      'reward': reward,
      'message': _getScoreMessage(percentage),
    };
  }

  String _getScoreMessage(double percentage) {
    if (percentage == 100) {
      return 'Perfect! 🎉';
    } else if (percentage >= 80) {
      return 'Excellent! 🌟';
    } else if (percentage >= 60) {
      return 'Good! 👍';
    } else if (percentage >= 40) {
      return 'Not bad! 😊';
    } else {
      return 'Keep trying! 💪';
    }
  }

  /// Record quiz result
  Future<void> recordQuizResult(
    String userId,
    int correctAnswers,
    int totalQuestions,
    double reward,
  ) async {
    try {
      await _firestoreService.recordGameResult(
        userId,
        'quiz',
        correctAnswers >= (totalQuestions ~/ 2),
        (reward * 1000).toInt(),
      );
      debugPrint(
        '✅ Quiz result recorded: $userId ($correctAnswers/$totalQuestions)',
      );
    } catch (e) {
      debugPrint('❌ Error recording quiz result: $e');
      rethrow;
    }
  }

  /// Get difficulty level based on category
  String getDifficultyLevel(String category) {
    switch (category) {
      case 'Mathematics':
      case 'Physics':
        return 'Hard';
      case 'General Knowledge':
      case 'Geography':
        return 'Medium';
      default:
        return 'Easy';
    }
  }

  /// Get all categories
  List<String> getAllCategories() {
    final categories = <String>{};
    for (var question in _questionBank) {
      categories.add(question.category);
    }
    return categories.toList();
  }

  /// Get questions by category
  List<QuizQuestion> getQuestionsByCategory(String category) {
    return _questionBank.where((q) => q.category == category).toList();
  }
}
