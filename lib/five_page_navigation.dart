/// Snapchat-style navigation between a center page and four side pages.
///
/// The main entry point is [FivePageNavigator]. Control it with a
/// [FivePageController] or [FivePageNavigator.of], and pick an animation
/// from [FivePageTransition].
library;

export 'src/configs/page_preview_style.dart';
export 'src/configs/return_button_style.dart';
export 'src/enums/page_type.dart';
export 'src/enums/swipe_direction.dart';
export 'src/enums/threshold_vibration.dart';
export 'src/five_page_navigator.dart';
export 'src/transitions/five_page_transition.dart';
