import 'package:flutter/material.dart';

/// Convenience helpers on [BuildContext].
extension LolipantsBuildContextX on BuildContext {
  /// Bottom safe area inset from [MediaQuery].
  double get lolipantsBottomInset => MediaQuery.paddingOf(this).bottom;
}
