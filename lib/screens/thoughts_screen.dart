import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thought.dart';
import '../providers/thoughts_provider.dart';
import '../providers/current_user_provider.dart';
import '../theme/app_theme.dart';

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {
  final _thoughtController = TextEditingController();
  double _mentalLoad = 1;

  @override
  Widget build(BuildContext context) {
    final allThoughts = ref.watch(thoughtsProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    // Filter thoughts to only show last 24 hours
    final now = DateTime.now();
    final thoughts = allThoughts.where((thought) {
      final difference = now.difference(thought.date);
      return difference.inHours <= 24;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Load'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _thoughtController,
                  decoration: const InputDecoration(
                    labelText: 'What household task is on your mind?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How much mental load does this create? (1-10)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _mentalLoad,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _mentalLoad.round().toString(),
                  onChanged: (value) => setState(() => _mentalLoad = value),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_thoughtController.text.isNotEmpty) {
                      ref.read(thoughtsProvider.notifier).addThought(
                        Thought(
                          text: _thoughtController.text,
                          mentalLoad: _mentalLoad,
                          userId: currentUser.id,
                          userName: currentUser.name,
                          userAvatar: currentUser.avatarUrl,
                        ),
                      );
                      _thoughtController.clear();
                      setState(() => _mentalLoad = 1);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Thought'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.userColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Your mental load'),
                      const SizedBox(width: 32),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.partnerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Partner\'s mental load'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: thoughts.map((thought) {
                        final size = thought.mentalLoad * 15;
                        final isCurrentUser = thought.userId == currentUser.id;
                        
                        return GestureDetector(
                          onTap: () => _showThoughtDetails(context, thought),
                          onLongPress: () => ref.read(thoughtsProvider.notifier).removeThought(thought),
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: isCurrentUser 
                                  ? AppColors.userColor 
                                  : AppColors.partnerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                thought.text,
                                style: TextStyle(
                                  fontSize: size * 0.2,  // Adjust text size relative to bubble size
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThoughtDetails(BuildContext context, Thought thought) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(thought.text),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mental Load: ${thought.mentalLoad.round()}/10'),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(thought.userAvatar),
                  radius: 12,
                ),
                const SizedBox(width: 8),
                Text(thought.userName),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 