import 'package:flutter/material.dart';

/// The left page. It has no AppBar, so it handles the safe area itself.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.primaryContainer,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: scheme.primary,
                  child: Icon(Icons.person, size: 56, color: scheme.onPrimary),
                ),
                const SizedBox(height: 16),
                Text('Profile', style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Left page without an AppBar. Swipe left from the right '
                  'side to go back.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const _Counter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows that a side page keeps its state while it is visible, including
/// during the swipe-back gesture.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _likes = 0;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => setState(() => _likes++),
      icon: const Icon(Icons.favorite),
      label: Text('$_likes likes'),
    );
  }
}
