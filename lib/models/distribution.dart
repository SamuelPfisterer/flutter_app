class Distribution {
  final double userPercentage;
  final double partnerPercentage;
  final Duration userDuration;
  final Duration partnerDuration;
  
  Distribution({
    required this.userPercentage,
    required this.partnerPercentage,
    required this.userDuration,
    required this.partnerDuration,
  });
}

class TaskDistribution {
  final String person;
  final double percentage;
  
  TaskDistribution(this.person, this.percentage);
} 