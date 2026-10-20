import 'package:five_page_navigation/five_page_navigation.dart';
import 'package:flutter/material.dart';

import '../demo_settings.dart';

/// The center page: shows the active page, a D-pad and the demo options.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.settings,
    required this.onSettingsChanged,
  });

  final FivePageController controller;
  final DemoSettings settings;
  final ValueChanged<DemoSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Five Page Navigation'),
        // All pages share one route; this keeps the center page's AppBar
        // unchanged while a side page (with its own back button) opens.
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  isDesktopOrWeb
                      ? 'Drag from an edge with the mouse, use the buttons '
                          'below or press Alt + arrow keys. Esc goes back.'
                      : 'Swipe from any edge of the screen, or use the '
                          'buttons below.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _DirectionPad(controller: controller),
                const SizedBox(height: 32),
                Text('Transition', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in demoTransitions.keys)
                      ChoiceChip(
                        label: Text(name),
                        selected: settings.transition == name,
                        onSelected: (_) => onSettingsChanged(
                          settings.copyWith(transition: name),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Options', style: theme.textTheme.titleMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Side page previews'),
                  subtitle: const Text('Show a label while swiping'),
                  value: settings.previews,
                  onChanged: (value) =>
                      onSettingsChanged(settings.copyWith(previews: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Return buttons'),
                  subtitle: const Text('A button on each side page'),
                  value: settings.returnButtons,
                  onChanged: (value) => onSettingsChanged(
                    settings.copyWith(returnButtons: value),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Swipe back'),
                  subtitle: const Text('Drag side pages back to the center'),
                  value: settings.swipeBack,
                  onChanged: (value) =>
                      onSettingsChanged(settings.copyWith(swipeBack: value)),
                ),
                if (!isDesktopOrWeb)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Haptic feedback'),
                    subtitle: const Text('Vibrate when a swipe will commit'),
                    value: settings.haptics,
                    onChanged: (value) =>
                        onSettingsChanged(settings.copyWith(haptics: value)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.controller});

  final FivePageController controller;

  @override
  Widget build(BuildContext context) {
    Widget button(PageType page, IconData icon, String label) {
      return IconButton.filledTonal(
        iconSize: 32,
        tooltip: label,
        icon: Icon(icon),
        onPressed: () => controller.navigateTo(page),
      );
    }

    return Column(
      children: [
        button(PageType.top, Icons.notifications_outlined, 'Notifications'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            button(PageType.left, Icons.person_outline, 'Profile'),
            Padding(
              padding: const EdgeInsets.all(16),
              // Rebuilds when the active page changes.
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Chip(
                  avatar: const Icon(Icons.home_outlined),
                  label: Text(controller.currentPage.name),
                ),
              ),
            ),
            button(PageType.right, Icons.chat_bubble_outline, 'Messages'),
          ],
        ),
        button(PageType.bottom, Icons.explore_outlined, 'Discover'),
      ],
    );
  }
}
