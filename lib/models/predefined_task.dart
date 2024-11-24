class PredefinedTask {
  final String id;
  final String title;
  final Duration effort;

  PredefinedTask({
    required this.id,
    required this.title,
    required this.effort,
  });

  String get formattedEffort {
    final hours = effort.inHours;
    final minutes = (effort.inMinutes % 60);
    return '${hours > 0 ? '${hours}h ' : ''}${minutes > 0 ? '${minutes}m' : ''}';
  }
} 