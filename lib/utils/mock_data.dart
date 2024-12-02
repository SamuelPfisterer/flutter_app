import 'dart:math';
import '../models/thought.dart';

class MockData {
  static List<Thought> generateMockThoughts() {
    final now = DateTime.now();
    final currentUserId = "franca";
    final partnerId = "christian";
    final random = Random();
    
    List<Thought> thoughts = [];

    List<String> thoughtNames = [
      "Plan weekly meals.",
      "Schedule teacher conferences.",
      "Track homework deadlines.",
      "Organize cleaning schedule.",
      "Plan family activities.",
      "Handle daily routines.",
      "Coordinate pickups/drop-offs.",
      "Pack school/work lunches.",
      "Track doctor appointments.",
      "Budget and pay bills.",
      "Do and fold laundry.",
      "Support kids emotionally.",
      "Plan holiday preparations.",
      "Monitor kids’ screen time.",
      "Split household tasks.",
      "Arrange house maintenance.",
      "Stock household supplies.",
      "Organize seasonal wardrobes.",
      "Communicate with teachers.",
      "Ensure healthy eating habits.",
      "Prepare for emergencies.",
      "Maintain family calendar.",
      "Teach kids life skills.",
      "Review insurance policies.",
      "Organize family keepsakes.",
      "Help kids with friendships."
    ];


    // Generate data for each week (4 weeks back)
    for (int week = 0; week < 4; week++) {
      // Generate 3 thoughts per day for each person
      for (int day = 0; day < 7; day++) {
        final date = now.subtract(Duration(days: week * 7 + day));
        
        // Add thoughts for current user
        thoughts.add(Thought(
          text: thoughtNames[random.nextInt(thoughtNames.length)],
          mentalLoad: 5.0 + (random.nextDouble() * 3),  // Random between 5-8
          userId: currentUserId,
          userName: "Franca",
          userAvatar: "https://image.gala.de/22980002/t/Os/v4/w2048/r0/-/franca-lehfeldt-pferd.jpg",
          date: date,
        ));

        // Add thoughts for partner
        if (random.nextBool()) {
          thoughts.add(Thought(
            text: thoughtNames[random.nextInt(thoughtNames.length)],
            mentalLoad: 2.0 + (random.nextDouble() * 3),
            // Random between 2-5
            userId: partnerId,
            userName: "Christian",
            userAvatar: "https://cdn.prod.www.spiegel.de/images/9fd2aa2f-01a2-4837-8875-c4ee51ad1c45_w1200_r1.33_fpx35_fpy23.jpg",
            date: date,
          ));
        }
      }
    }

    // Sort thoughts by date (most recent first)
    thoughts.sort((a, b) => b.date.compareTo(a.date));
    return thoughts;
  }
} 