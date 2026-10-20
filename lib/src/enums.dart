/// Defines where the state-based `Decoration` is drawn relative to the child widget.
enum DecorationPlacement {
  /// Wraps the child widget inside the decorated container.
  background,

  /// Overlays the decoration directly on top of the child widget using a `Stack`.
  foreground,
}

/// Defines where the validation error text is displayed relative to the input widget.
enum ErrorPosition {
  /// Displays the error message directly below the custom input widget.
  bottom,

  /// Displays the error message directly above the custom input widget.
  top,

  /// Disables rendering the error message entirely.
  none,
}
