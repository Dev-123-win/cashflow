class Task {
  final String taskId;
  final String title;
  final String description;
  final int reward; // Changed to int for Coins
  final String? icon;
  final String actionUrl;
  final String category;
  final String duration;
  final bool completed;
  final DateTime? nextAvailableAt;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.reward,
    this.icon,
    this.actionUrl = '',
    this.category = 'general',
    this.duration = '',
    this.completed = false,
    this.nextAvailableAt,
  });

  // Alias for compatibility
  String get id => taskId;

  Task copyWith({
    String? taskId,
    String? title,
    String? description,
    int? reward,
    String? icon,
    String? actionUrl,
    String? category,
    String? duration,
    bool? completed,
    DateTime? nextAvailableAt,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      icon: icon ?? this.icon,
      actionUrl: actionUrl ?? this.actionUrl,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      nextAvailableAt: nextAvailableAt ?? this.nextAvailableAt,
    );
  }

  factory Task.empty() {
    return Task(taskId: '', title: '', description: '', reward: 0);
  }
}
