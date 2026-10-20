import 'package:flutter/widgets.dart';

/// Constant width used by the default decorations in every state, so that
/// focusing the field or showing an error never changes its layout size.
const double kDefaultBorderWidth = 1.5;

/// Recolors the visible border sides of [base] with [color], keeping widths.
/// Anything that is not a [BoxDecoration] with a [Border] or
/// [BorderDirectional] is returned unchanged.
Decoration deriveErrorDecoration(Decoration base, Color color) {
  BorderSide recolor(BorderSide side) =>
      side.style == BorderStyle.none ? side : side.copyWith(color: color);

  if (base is BoxDecoration) {
    final border = base.border;
    if (border is Border) {
      return base.copyWith(
        border: Border(
          top: recolor(border.top),
          right: recolor(border.right),
          bottom: recolor(border.bottom),
          left: recolor(border.left),
        ),
      );
    }
    if (border is BorderDirectional) {
      return base.copyWith(
        border: BorderDirectional(
          top: recolor(border.top),
          start: recolor(border.start),
          end: recolor(border.end),
          bottom: recolor(border.bottom),
        ),
      );
    }
  }
  return base;
}
