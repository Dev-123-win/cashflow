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

  /// Question bank
  final List<QuizQuestion> _questionBank = [
    // General Knowledge
    QuizQuestion(
      id: 'q1',
      question: 'What is the capital of France?',
      options: ['London', 'Berlin', 'Paris', 'Madrid'],
      correctAnswerIndex: 2,
      category: 'General Knowledge',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'Which planet is known as the Red Planet?',
      options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      correctAnswerIndex: 1,
      category: 'General Knowledge',
    ),
    QuizQuestion(
      id: 'q3',
      question: 'What is the largest ocean on Earth?',
      options: [
        'Atlantic Ocean',
        'Indian Ocean',
        'Arctic Ocean',
        'Pacific Ocean',
      ],
      correctAnswerIndex: 3,
      category: 'General Knowledge',
    ),
    QuizQuestion(
      id: 'q4',
      question: 'In which year did the Titanic sink?',
      options: ['1912', '1915', '1920', '1925'],
      correctAnswerIndex: 0,
      category: 'History',
    ),
    QuizQuestion(
      id: 'q5',
      question: 'Who wrote "Romeo and Juliet"?',
      options: [
        'John Milton',
        'William Shakespeare',
        'Jane Austen',
        'Charles Dickens',
      ],
      correctAnswerIndex: 1,
      category: 'Literature',
    ),
    QuizQuestion(
      id: 'q6',
      question: 'What is the chemical symbol for gold?',
      options: ['Go', 'Gd', 'Au', 'Ag'],
      correctAnswerIndex: 2,
      category: 'Science',
    ),
    QuizQuestion(
      id: 'q7',
      question: 'Which country has the most population?',
      options: ['India', 'China', 'USA', 'Indonesia'],
      correctAnswerIndex: 0,
      category: 'Geography',
    ),
    QuizQuestion(
      id: 'q8',
      question: 'What is the smallest prime number?',
      options: ['0', '1', '2', '3'],
      correctAnswerIndex: 2,
      category: 'Mathematics',
    ),
    QuizQuestion(
      id: 'q9',
      question: 'Who is the CEO of Tesla?',
      options: ['Bill Gates', 'Elon Musk', 'Jeff Bezos', 'Mark Zuckerberg'],
      correctAnswerIndex: 1,
      category: 'Business',
    ),
    QuizQuestion(
      id: 'q10',
      question: 'What is the speed of light?',
      options: ['300,000 km/s', '150,000 km/s', '450,000 km/s', '600,000 km/s'],
      correctAnswerIndex: 0,
      category: 'Physics',
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
        reward,
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
