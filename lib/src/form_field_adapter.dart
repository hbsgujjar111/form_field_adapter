import 'package:flutter/material.dart';

import 'decoration_utils.dart';
import 'enums.dart';
import 'form_field_container.dart';

/// A highly interactive, focus-aware custom [FormField] wrapper designed for Flutter.
///
/// Wrap any custom input widget returned from [builder] to give it validation,
/// state-based decorations, a shake animation and haptic feedback:
///
/// ```dart
/// FormFieldAdapter<int>(
///   focusNode: node,
///   validator: (value) => (value ?? 0) < 3 ? 'Pick at least 3' : null,
///   builder: (state) => Focus(
///     focusNode: node,
///     child: MyRatingBar(onChanged: state.didChange),
///   ),
/// )
/// ```
///
/// **Focus tracking.** The adapter only listens to `focusNode`; it does not
/// attach it. Pass the same node to a [Focus] widget (or a focusable field)
/// inside `builder`, otherwise the focused decorations are never used.
///
/// **Decorations.** The active decoration is resolved as follows:
/// disabled with `disabledDecoration`: `disabledDecoration`;
/// focused with error: `focusedErrorDecoration`, then `errorDecoration`;
/// error: `errorDecoration`; focused: `focusedDecoration`, then
/// `normalDecoration`; otherwise `normalDecoration`. When there is an error
/// but no error decoration, the error state is derived from the focused or
/// normal decoration: if it is a [BoxDecoration] with a [Border] or
/// [BorderDirectional], every visible side is recolored with the theme's error
/// color (widths are kept); any other decoration is reused unchanged. Without
/// any decoration, a themed bottom border of constant width is used. Keep the
/// border widths of your own decorations equal across states, because a
/// [Border] contributes to layout and different widths shift the content.
///
/// **Validation.** `autovalidateMode` defaults to
/// [AutovalidateMode.onUserInteraction] (the framework default is
/// [AutovalidateMode.disabled]). The older spelling `autoValidateMode` still
/// works but is deprecated.
///
/// **Feedback.** The shake and the haptic fire when the field becomes invalid
/// and every time an explicit validation (for example `FormState.validate()`)
/// fails again. Automatic validation while the user types does not repeat the
/// feedback for an error that is already showing. Feedback is skipped when the
/// field is disabled. The shake is skipped when
/// [MediaQuery.disableAnimationsOf] is true. The error text is announced to
/// screen readers as a live region.
///
/// **Scrolling.** With `ensureVisibleOnError`, an explicit validation that
/// fails scrolls the topmost invalid field into view (with an animation, or
/// instantly when [MediaQuery.disableAnimationsOf] is true).
///
/// **Layout.** `crossAxisAlignment` aligns the decorated input and the error
/// text. The default error padding is directional, so it follows the ambient
/// [TextDirection].
class FormFieldAdapter<T> extends FormField<T> {
  /// Creates a form field that wraps the widget returned by [builder].
  FormFieldAdapter({
    super.key,
    super.initialValue,
    required Widget Function(FormFieldState<T> state) builder,
    super.validator,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.restorationId,
    this.onChanged,
    AutovalidateMode? autovalidateMode,
    @Deprecated('Use autovalidateMode instead. Will be removed in 2.0.0.')
    AutovalidateMode? autoValidateMode,
    super.enabled,

    // Focus tracking
    FocusNode? focusNode,

    // State-based Custom Decorations
    Decoration? normalDecoration,
    Decoration? errorDecoration,
    Decoration? focusedDecoration,
    Decoration? focusedErrorDecoration,
    Decoration? disabledDecoration,
    DecorationPlacement decorationPlacement = DecorationPlacement.background,

    // Feedback Customizations
    bool enableShake = true,
    bool enableHaptics = true,
    Duration shakeDuration = const Duration(milliseconds: 350),
    double shakeOffset = 8.0,
    Duration animationDuration = const Duration(milliseconds: 200),
    bool ensureVisibleOnError = false,

    // Alignment and Layout Customizations
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    TextAlign? errorTextAlign,

    // Error text styling and positions
    ErrorPosition errorPosition = ErrorPosition.bottom,
    TextStyle? errorTextStyle,
    EdgeInsetsGeometry? errorPadding,
    Widget Function(BuildContext context, String errorText)? errorBuilder,
  }) : super(
         autovalidateMode:
             autovalidateMode ??
             autoValidateMode ??
             AutovalidateMode.onUserInteraction,
         builder: (state) {
           final context = state.context;
           final theme = Theme.of(context);
           final disableAnimations =
               MediaQuery.maybeDisableAnimationsOf(context) ?? false;
           final validationFailures = state is _FormFieldAdapterState<T>
               ? state._validationFailures
               : 0;

           // Automatic Theme Copying for Error Text Styling
           final resolvedErrorColor = theme.colorScheme.error;
           final resolvedErrorTextStyle =
               errorTextStyle ??
               theme.inputDecorationTheme.errorStyle ??
               theme.textTheme.bodySmall?.copyWith(color: resolvedErrorColor) ??
               TextStyle(color: resolvedErrorColor, fontSize: 12);

           final hasError = state.hasError;

           // Helper methods to generate default decorations if the user didn't provide any
           Decoration defaultNormalDeco(bool focused) => BoxDecoration(
             border: Border(
               bottom: BorderSide(
                 color: focused
                     ? theme.colorScheme.primary
                     : theme.colorScheme.onSurface.withValues(alpha: .38),
                 width: kDefaultBorderWidth,
               ),
             ),
           );

           Decoration defaultErrorDeco(bool focused) => BoxDecoration(
             border: Border(
               bottom: BorderSide(
                 color: resolvedErrorColor,
                 width: kDefaultBorderWidth,
               ),
             ),
           );

           // Derives the error look from a normal/focused decoration.
           Decoration deriveErrorDeco(Decoration base) =>
               deriveErrorDecoration(base, resolvedErrorColor);

           // Resolve the text alignment based on the column's cross axis alignment
           final resolvedErrorTextAlign =
               errorTextAlign ??
               (crossAxisAlignment == CrossAxisAlignment.center
                   ? TextAlign.center
                   : (crossAxisAlignment == CrossAxisAlignment.end
                         ? TextAlign.end
                         : TextAlign.start));

           final decoratedInput = FormFieldContainer(
             focusNode: focusNode,
             hasError: hasError,
             enabled: state.widget.enabled,
             validationFailures: validationFailures,
             enableShake: enableShake,
             enableHaptics: enableHaptics,
             disableAnimations: disableAnimations,
             ensureVisibleOnError: ensureVisibleOnError,
             shakeDuration: shakeDuration,
             shakeOffset: shakeOffset,
             animationDuration: animationDuration,
             normalDecoration: normalDecoration,
             errorDecoration: errorDecoration,
             focusedDecoration: focusedDecoration,
             focusedErrorDecoration: focusedErrorDecoration,
             disabledDecoration: disabledDecoration,
             defaultNormalDecorationBuilder: defaultNormalDeco,
             defaultErrorDecorationBuilder: defaultErrorDeco,
             deriveErrorDecoration: deriveErrorDeco,
             decorationPlacement: decorationPlacement,
             child: builder(state),
           );

           return Column(
             crossAxisAlignment:
                 crossAxisAlignment, // <-- Dynamically align the whole widget
             mainAxisSize: MainAxisSize.min,
             children: [
               if (hasError &&
                   state.errorText != null &&
                   errorPosition == ErrorPosition.top)
                 _buildErrorWidget(
                   context,
                   state.errorText!,
                   errorBuilder,
                   resolvedErrorTextStyle,
                   errorPadding ??
                       const EdgeInsetsDirectional.only(bottom: 6, start: 4),
                   resolvedErrorTextAlign, // <-- Align the text
                 ),

               decoratedInput,

               if (hasError &&
                   state.errorText != null &&
                   errorPosition == ErrorPosition.bottom)
                 _buildErrorWidget(
                   context,
                   state.errorText!,
                   errorBuilder,
                   resolvedErrorTextStyle,
                   errorPadding ??
                       const EdgeInsetsDirectional.only(top: 6, start: 4),
                   resolvedErrorTextAlign, // <-- Align the text
                 ),
             ],
           );
         },
       );

  /// Called with the new value whenever the field value changes through
  /// [FormFieldState.didChange] (for example when the user interacts with the
  /// widget returned by `builder`).
  ///
  /// It is not called by [FormFieldState.reset] or [FormFieldState.setValue].
  final ValueChanged<T?>? onChanged;

  @override
  FormFieldState<T> createState() => _FormFieldAdapterState<T>();

  static Widget _buildErrorWidget(
    BuildContext context,
    String errorText,
    Widget Function(BuildContext, String)? customBuilder,
    TextStyle style,
    EdgeInsetsGeometry padding,
    TextAlign textAlign,
  ) {
    final Widget error = customBuilder != null
        ? customBuilder(context, errorText)
        : Padding(
            padding: padding,
            child: Text(
              errorText,
              style: style,
              textAlign: textAlign, // <-- Apply text alignment
            ),
          );
    // Announce the error to screen readers when it appears.
    return Semantics(liveRegion: true, container: true, child: error);
  }
}

/// Counts explicit validations that failed and forwards value changes.
class _FormFieldAdapterState<T> extends FormFieldState<T> {
  int _validationFailures = 0;

  @override
  bool validate() {
    final bool valid = super.validate();
    if (!valid) {
      // The rebuild scheduled by super.validate() reads the new count.
      _validationFailures++;
    }
    return valid;
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    (widget as FormFieldAdapter<T>).onChanged?.call(value);
  }
}
