import 'package:flutter/material.dart';

/// The bottom page. It has an AppBar and a bottom navigation bar; the return
/// button is placed below the AppBar instead of covering it.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 64, 12, 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 24,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.primaryContainer,
              scheme.tertiaryContainer,
              index / 24,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text('${index + 1}')),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}
