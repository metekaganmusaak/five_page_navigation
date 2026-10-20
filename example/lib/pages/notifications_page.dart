import 'package:flutter/material.dart';

/// The top page. A long list shows that scrolling and the swipe-back gesture
/// from the lower part of the page work together.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: scheme.tertiaryContainer,
        // The center page is below, so a "down" arrow fits better than the
        // automatic back arrow.
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text('Notification #${index + 1}'),
          subtitle: Text('${index + 1} min ago'),
        ),
      ),
    );
  }
}
