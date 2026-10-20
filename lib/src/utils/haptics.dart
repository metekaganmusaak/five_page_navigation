import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../enums/threshold_vibration.dart';

/// Plays [vibration] on platforms that have a haptic engine.
///
/// Desktop embedders have no haptics, so the call is skipped there instead of
/// sending a platform message that nobody handles. On the web,
/// [defaultTargetPlatform] reflects the browser's OS, so mobile browsers still
/// vibrate.
void playThresholdFeedback(ThresholdVibration vibration) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      break;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return;
  }

  switch (vibration) {
    case ThresholdVibration.none:
      break;
    case ThresholdVibration.soft:
      HapticFeedback.lightImpact();
    case ThresholdVibration.medium:
      HapticFeedback.mediumImpact();
    case ThresholdVibration.heavy:
      HapticFeedback.heavyImpact();
    case ThresholdVibration.selection:
      HapticFeedback.selectionClick();
  }
}
