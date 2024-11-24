import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thought.dart';

final thoughtsProvider = StateNotifierProvider<ThoughtsNotifier, List<Thought>>((ref) {
  return ThoughtsNotifier();
});

class ThoughtsNotifier extends StateNotifier<List<Thought>> {
  ThoughtsNotifier() : super([]);

  void addThought(Thought thought) {
    state = [...state, thought];
  }

  void removeThought(Thought thought) {
    state = state.where((t) => t != thought).toList();
  }

  void clearThoughts() {
    state = [];
  }
} 