import 'package:five_page_navigation/five_page_navigation.dart';
import 'package:flutter/foundation.dart';

/// Every built-in transition, keyed by the name shown in the picker.
const Map<String, FivePageTransition> demoTransitions = {
  'Slide': FivePageTransition.slide(),
  'Parallax': FivePageTransition.parallax(),
  'Cover': FivePageTransition.cover(),
  'Depth': FivePageTransition.depth(),
  'Reveal': FivePageTransition.reveal(),
  'Fade': FivePageTransition.fade(),
  'Fade through': FivePageTransition.fadeThrough(),
  'Shared axis': FivePageTransition.sharedAxis(),
  'Zoom': FivePageTransition.zoom(),
  'Scale': FivePageTransition.scale(),
  'Cube': FivePageTransition.cube(),
  'Flip': FivePageTransition.flip(),
  'Rotate': FivePageTransition.rotate(),
  'None': FivePageTransition.none(),
};

/// Whether the app runs with a mouse and keyboard as primary input.
bool get isDesktopOrWeb =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };

/// The options that can be changed from the center page.
@immutable
class DemoSettings {
  const DemoSettings({
    this.transition = 'Slide',
    this.previews = false,
    this.returnButtons = true,
    this.swipeBack = true,
    this.haptics = true,
  });

  final String transition;
  final bool previews;
  final bool returnButtons;
  final bool swipeBack;
  final bool haptics;

  DemoSettings copyWith({
    String? transition,
    bool? previews,
    bool? returnButtons,
    bool? swipeBack,
    bool? haptics,
  }) {
    return DemoSettings(
      transition: transition ?? this.transition,
      previews: previews ?? this.previews,
      returnButtons: returnButtons ?? this.returnButtons,
      swipeBack: swipeBack ?? this.swipeBack,
      haptics: haptics ?? this.haptics,
    );
  }
}
