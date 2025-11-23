class Task {
  final String taskId;
  final String title;
  final String description;
  final String type;
  final double reward;
  final int timeRequired;
  final bool completed;
  final DateTime? completedAt;
  final DateTime nextAvailableAt;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.type,
    required this.reward,
    required this.timeRequired,
    required this.completed,
    this.completedAt,
    required this.nextAvailableAt,
  });

  factory Task.empty() {
    return Task(
      taskId: '',
      title: '',
      description: '',
      type: '',
      reward: 0,
      timeRequired: 0,
      completed: false,
      nextAvailableAt: DateTime.now(),
    );
  }
}
