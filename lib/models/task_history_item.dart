class TaskHistoryItem {
  final String title;
  final String userName;
  final DateTime completedAt;
  final String userAvatar;
  final Duration duration;
  final bool thanked;

  TaskHistoryItem({
    required this.title,
    required this.userName,
    required this.completedAt,
    required this.userAvatar,
    required this.duration,
    this.thanked = false,
  });
} 