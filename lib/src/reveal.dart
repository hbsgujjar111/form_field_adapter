import 'package:flutter/widgets.dart';

final List<BuildContext> _pendingReveals = <BuildContext>[];

/// Queues [context] to be scrolled into view after the current frame. When
/// several fields fail in the same frame, only the topmost one is revealed.
///
/// The scroll is animated, unless the platform asks to reduce motion
/// ([MediaQuery.disableAnimationsOf]); then it jumps.
void requestReveal(BuildContext context) {
  // Drop stale entries (e.g. from a field that was disposed before the frame
  // ended) so a missed callback can never block later requests.
  _pendingReveals.removeWhere((c) => !c.mounted);
  final bool firstRequest = _pendingReveals.isEmpty;
  _pendingReveals.add(context);
  if (!firstRequest) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final candidates = _pendingReveals.where((c) => c.mounted).toList();
    _pendingReveals.clear();

    BuildContext? topmost;
    double topmostY = double.infinity;
    for (final candidate in candidates) {
      final renderObject = candidate.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;
      final y = renderObject.localToGlobal(Offset.zero).dy;
      if (y < topmostY) {
        topmostY = y;
        topmost = candidate;
      }
    }
    if (topmost != null) {
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(topmost) ?? false;
      Scrollable.ensureVisible(
        topmost,
        alignment: 0.1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}
