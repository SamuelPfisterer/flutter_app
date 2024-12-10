import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thought.dart';
import '../providers/thoughts_provider.dart';
import '../providers/current_user_provider.dart';
import '../theme/app_theme.dart';

// Common household and family tasks templates
final _thoughtTemplates = [
  {'text': 'Meal planning', 'load': 6.0},
  {'text': 'Planning vacation', 'load': 7.0},
  {'text': 'Laundry', 'load': 4.0},
  {'text': 'Helping kids with school', 'load': 7.0},
  {'text': 'Grocery shopping', 'load': 5.0},
  {'text': 'House cleaning', 'load': 6.0},
  {'text': 'Doctor appointments', 'load': 5.0},
  {'text': 'Kids activities', 'load': 6.0},
];

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {
  final _thoughtController = TextEditingController();
  double _mentalLoad = 5;
  bool _showInputForm = false;
  bool _showMentalLoadSlider = false;
  int? _selectedTemplateIndex;
  String? _lastTemplateText;

  @override
  void initState() {
    super.initState();
    _thoughtController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _thoughtController.removeListener(_onTextChanged);
    _thoughtController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_thoughtController.text.isNotEmpty && !_showMentalLoadSlider) {
      setState(() {
        _showMentalLoadSlider = true;
      });
    } else if (_thoughtController.text.isEmpty && _showMentalLoadSlider) {
      setState(() {
        _showMentalLoadSlider = false;
        _selectedTemplateIndex = null;
      });
    }
    
    // Deselect template if text is modified
    if (_selectedTemplateIndex != null && 
        _thoughtController.text != _lastTemplateText) {
      setState(() {
        _selectedTemplateIndex = null;
      });
    }
  }

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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Thoughts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: !_showInputForm ? () => setState(() => _showInputForm = true) : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Thought'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
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
                        child: thoughts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.psychology_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No thoughts yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap "+ Add Thought" to share what\'s on your mind',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Wrap(
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
                                            fontSize: size * 0.2,
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
          if (_showInputForm)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'New Thought',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showInputForm = false;
                                    _thoughtController.clear();
                                    _mentalLoad = 1;
                                    _showMentalLoadSlider = false;
                                    _selectedTemplateIndex = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Quick select section with background
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose a common thought or type your own below',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _thoughtTemplates.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final template = entry.value;
                                      final isSelected = index == _selectedTemplateIndex;
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ActionChip(
                                          label: Text(template['text'] as String),
                                          onPressed: () {
                                            setState(() {
                                              _thoughtController.text = template['text'] as String;
                                              _mentalLoad = template['load'] as double;
                                              _showMentalLoadSlider = true;
                                              _selectedTemplateIndex = index;
                                              _lastTemplateText = template['text'] as String;
                                            });
                                          },
                                          backgroundColor: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.surfaceVariant,
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                          TextField(
                            controller: _thoughtController,
                            autofocus: false, // Changed to false since we want users to see quick select first
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Type your own thought or use quick select above',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _showMentalLoadSlider
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Mental Load (1-10)',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _mentalLoad.round().toString(),
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.sentiment_satisfied, color: Colors.green),
                                          Expanded(
                                            child: Slider(
                                              value: _mentalLoad,
                                              min: 1,
                                              max: 10,
                                              divisions: 9,
                                              label: _mentalLoad.round().toString(),
                                              onChanged: (value) => setState(() => _mentalLoad = value),
                                            ),
                                          ),
                                          const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
                                        ],
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _thoughtController.text.isEmpty
                                ? null // Disable button when no text
                                : () {
                                    if (_thoughtController.text.isNotEmpty) {
                                      ref.read(thoughtsProvider.notifier).addThought(
                                        Thought(
                                          text: _thoughtController.text,
                                          mentalLoad: _mentalLoad,
                                          userId: ref.read(currentUserProvider).id,
                                          userName: ref.read(currentUserProvider).name,
                                          userAvatar: ref.read(currentUserProvider).avatarUrl,
                                        ),
                                      );
                                      _thoughtController.clear();
                                      setState(() {
                                        _showInputForm = false;
                                        _mentalLoad = 1;
                                        _showMentalLoadSlider = false;
                                        _selectedTemplateIndex = null;
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.check),
                            label: const Text('Save Thought'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
} 