import 'dart:math';
import '../models/thought.dart';

class MockData {
  static List<Thought> generateMockThoughts() {
    final now = DateTime.now();
    final currentUserId = "user1";
    final partnerId = "user2";
    
    return [
      // Today's data points (every 3 hours)
      ...List.generate(8, (i) => Thought(
        text: "Mock thought",
        mentalLoad: 3.0 + (i * 0.5),
        userId: currentUserId,
        userName: "You",
        userAvatar: "avatar1.jpg",
        date: DateTime(now.year, now.month, now.day, i * 3),
      )),
      
      // Partner's today data
      ...List.generate(8, (i) => Thought(
        text: "Partner thought",
        mentalLoad: 2.0 + (i * 0.3),
        userId: partnerId,
        userName: "Partner",
        userAvatar: "avatar2.jpg",
        date: DateTime(now.year, now.month, now.day, i * 3),
      )),
      
      // Past week data
      ...List.generate(7, (i) => Thought(
        text: "Past thought",
        mentalLoad: 4.0 + (i * 0.7),
        userId: currentUserId,
        userName: "You",
        userAvatar: "avatar1.jpg",
        date: now.subtract(Duration(days: i)),
      )),
      
      // Partner's past week
      ...List.generate(7, (i) => Thought(
        text: "Partner past",
        mentalLoad: 3.0 + (i * 0.5),
        userId: partnerId,
        userName: "Partner",
        userAvatar: "avatar2.jpg",
        date: now.subtract(Duration(days: i)),
      )),
      
      // Monthly data
      ...List.generate(30, (i) => Thought(
        text: "Monthly thought",
        mentalLoad: 5.0 + (sin(i * 0.2) * 2),
        userId: currentUserId,
        userName: "You",
        userAvatar: "avatar1.jpg",
        date: now.subtract(Duration(days: i)),
      )),
    ];
  }
} 