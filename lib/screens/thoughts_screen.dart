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
        title: const Text('Thoughts'),
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
                    labelText: 'What is on your mind?',
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
                  style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
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
                      const Text('You'),
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
                      const Text('Partner'),
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
    final currentUser = ref.read(currentUserProvider);
    final isCurrentUser = thought.userId == currentUser.id;

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
          if (isCurrentUser) 
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Thought?'),
                    content: const Text('Are you sure you want to delete this thought? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(thoughtsProvider.notifier).removeThought(thought);
                          Navigator.pop(context); // Close confirmation dialog
                          Navigator.pop(context); // Close details dialog
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  void _showThoughtMenu(BuildContext context, Thought thought) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
          onTap: () => Future.delayed(
            const Duration(seconds: 0),
            () => _showThoughtDetails(context, thought),
          ),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => Future.delayed(
            const Duration(seconds: 0),
            () => _showDeleteConfirmation(context, thought),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Thought thought) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thought?'),
        content: const Text('Are you sure you want to delete this thought? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(thoughtsProvider.notifier).removeThought(thought);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 