import 'package:flutter/material.dart';

/// The right page. Its AppBar shows an automatic back button that returns to
/// the center page.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static const _names = ['Ada', 'Linus', 'Grace', 'Alan', 'Margaret', 'Dennis'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: scheme.secondaryContainer,
      ),
      body: ListView.separated(
        itemCount: _names.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final name = _names[index];
          return ListTile(
            leading: CircleAvatar(child: Text(name[0])),
            title: Text(name),
            subtitle: const Text('Tap to send a reply'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Replied to $name')),
            ),
          );
        },
      ),
    );
  }
}
