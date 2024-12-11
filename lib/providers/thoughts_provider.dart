import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thought.dart';
import '../services/firebase_service.dart';

final thoughtsProvider = StateNotifierProvider<ThoughtsNotifier, List<Thought>>((ref) {
  return ThoughtsNotifier();
});

class ThoughtsNotifier extends StateNotifier<List<Thought>> {
  ThoughtsNotifier() : super([]) {
    // Listen to Firebase updates
    FirebaseService.listenToUpdates(() {
      // Refresh state when updates occur
      // In a real app, you'd want to be more selective about updates
      // but for simplicity, we'll refresh everything
      _loadThoughts();
    });
  }

  Future<void> _loadThoughts() async {
    // TODO: Load thoughts from Firebase
    // For now, we'll keep the local state
  }

  Future<void> addThought(Thought thought) async {
    state = [thought, ...state];
    // Sync to Firebase
    await FirebaseService.syncThought(thought);
  }
} 