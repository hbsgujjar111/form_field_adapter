/// An interactive, focus-aware `FormField` wrapper that adds state-based
/// decorations, shake animations, haptic feedback and optional scroll-to-error
/// to any custom widget.
///
/// The main entry point is [FormFieldAdapter]. [DecorationPlacement] and
/// [ErrorPosition] configure where the decoration and the error text are drawn.
library;

export 'src/enums.dart';
export 'src/form_field_adapter.dart' show FormFieldAdapter;
