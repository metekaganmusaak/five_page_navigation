/// The haptic feedback played when a swipe crosses its threshold.
///
/// Haptics are only played on Android and iOS (including mobile browsers).
/// On desktop platforms every value behaves like [none].
enum ThresholdVibration {
  /// No haptic feedback.
  none,

  /// A light impact (`HapticFeedback.lightImpact`).
  soft,

  /// A medium impact (`HapticFeedback.mediumImpact`).
  medium,

  /// A heavy impact (`HapticFeedback.heavyImpact`).
  heavy,

  /// A selection click (`HapticFeedback.selectionClick`).
  selection,
}
