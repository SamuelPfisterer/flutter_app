class Thought {
  final String text;
  final double mentalLoad;
  final DateTime date;
  final String userId;
  final String userName;
  final String userAvatar;

  Thought({
    required this.text,
    required this.mentalLoad,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    DateTime? date,
  }) : date = date ?? DateTime.now();
} 