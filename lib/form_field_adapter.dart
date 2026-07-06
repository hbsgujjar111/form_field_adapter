import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Defines where the state-based [Decoration] is drawn relative to the child widget.
enum DecorationPlacement {
  /// Wraps the child widget inside the decorated container.
  /// Use this if you want the decoration to act as the background or a physical border.
  background,

  /// Overlays the decoration directly on top of the child widget using a [Stack].
  /// Useful if your child widget already has internal padding, clip behavior,
  /// or styling that would otherwise shift when wrapping it.
  foreground,
}

/// Defines where the validation error text is displayed relative to the input widget.
enum ErrorPosition {
  /// Displays the error message directly below the custom input widget.
  bottom,

  /// Displays the error message directly above the custom input widget.
  top,

  /// Disables rendering the error message entirely.
  /// Use this if you want to handle error message rendering externally.
  none,
}

/// A highly interactive, focus-aware custom [FormField] wrapper designed for Flutter.
///
/// [FormFieldAdapter] simplifies turning any custom input widget (such as rating selectors,
/// tag chips, map pins, or image uploads) into a fully integrated form field.
///
/// It provides smooth, animated visual transitions between focus and error states,
/// haptic feedback, a subtle "shake" error animation, and flexible error placements.
class FormFieldAdapter<T> extends FormField<T> {
  /// Creates a new [FormFieldAdapter].
  ///
  /// The [builder] parameter must not be null and is responsible for rendering
  /// your custom input widget.
  FormFieldAdapter({
    super.key,
    super.initialValue,

    /// The builder that renders your custom input widget.
    /// Provides the current [FormFieldState] which contains values such as
    /// validation errors, the current value, and methods to update the field.
    required Widget Function(FormFieldState<T> state) builder,

    /// An optional validator function that takes the current value and returns
    /// an error string if validation fails, or null if the value is valid.
    super.validator,

    /// An optional callback called when the parent [Form] is saved.
    super.onSaved,

    /// Configures the auto-validation behavior.
    /// Defaults to [AutovalidateMode.onUserInteraction].
    AutovalidateMode? autoValidateMode,

    /// Whether the form field is interactive. If false, interactive decorations
    /// and focus indicators are disabled.
    super.enabled,

    /// An optional [FocusNode] to track the focus state of your custom widget.
    /// Passing this enables the wrapper to automatically switch to the focused
    /// decoration state when the user interacts with the widget.
    FocusNode? focusNode,

    /// The decoration applied when the field is enabled, not focused, and has no error.
    /// If null, a standard Material-style bottom border will be generated automatically.
    Decoration? normalDecoration,

    /// The decoration applied when the field is not focused but has a validation error.
    /// If null, a standard red Material-style bottom border will be generated automatically.
    Decoration? errorDecoration,

    /// The decoration applied when the field is focused and has no validation error.
    /// If null, a standard colored Material-style bottom border will be generated automatically.
    Decoration? focusedDecoration,

    /// The decoration applied when the field is focused and has a validation error.
    /// If null, a standard red Material-style bottom border will be generated automatically.
    Decoration? focusedErrorDecoration,

    /// Determines where the decoration is rendered relative to your child widget.
    /// Defaults to [DecorationPlacement.background].
    DecorationPlacement decorationPlacement = DecorationPlacement.background,

    /// Whether to perform a horizontal "shake" animation when a validation error
    /// is first triggered. Defaults to `true`.
    bool enableShake = true,

    /// Whether to trigger a light haptic vibration feedback on the device when
    /// a validation error is first triggered. Defaults to `true`.
    bool enableHaptics = true,

    /// The duration of the transition animation when switching between state decorations.
    /// Defaults to 200 milliseconds.
    Duration animationDuration = const Duration(milliseconds: 200),

    /// Where to place the error text message relative to the input widget.
    /// Defaults to [ErrorPosition.bottom].
    ErrorPosition errorPosition = ErrorPosition.bottom,

    /// Custom text style for the validation error message.
    /// If null, it automatically copies [InputDecorationTheme.errorStyle] from
    /// your current theme, falling back to your theme's [TextTheme.bodySmall].
    TextStyle? errorTextStyle,

    /// The padding surrounding the validation error message.
    /// Defaults to 6.0 pixels on the top or bottom depending on [errorPosition],
    /// and 4.0 pixels on the left.
    EdgeInsetsGeometry? errorPadding,

    /// A custom builder to completely customize how the error widget is rendered.
    /// Allows you to add warning icons, error banners, or custom animations instead
    /// of a simple text label.
    Widget Function(BuildContext context, String errorText)? errorBuilder,
  }) : super(
         autovalidateMode: autoValidateMode ?? AutovalidateMode.onUserInteraction,
         builder: (state) {
           final context = state.context;
           final theme = Theme.of(context);

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
                 color: focused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: .38),
                 width: focused ? 2.0 : 1.0,
               ),
             ),
           );

           Decoration defaultErrorDeco(bool focused) => BoxDecoration(
             border: Border(
               bottom: BorderSide(color: resolvedErrorColor, width: focused ? 2.0 : 1.0),
             ),
           );

           return _FormFieldContainer(
             focusNode: focusNode,
             hasError: hasError,
             enableShake: enableShake,
             enableHaptics: enableHaptics,
             animationDuration: animationDuration,
             normalDecoration: normalDecoration,
             errorDecoration: errorDecoration,
             focusedDecoration: focusedDecoration,
             focusedErrorDecoration: focusedErrorDecoration,
             defaultNormalDecorationBuilder: defaultNormalDeco,
             defaultErrorDecorationBuilder: defaultErrorDeco,
             decorationPlacement: decorationPlacement,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 // Position error text above if requested
                 if (hasError && state.errorText != null && errorPosition == ErrorPosition.top)
                   _buildErrorWidget(
                     context,
                     state.errorText!,
                     errorBuilder,
                     resolvedErrorTextStyle,
                     errorPadding ?? const EdgeInsets.only(bottom: 6, left: 4),
                   ),

                 builder(state),

                 // Position error text below if requested
                 if (hasError && state.errorText != null && errorPosition == ErrorPosition.bottom)
                   _buildErrorWidget(
                     context,
                     state.errorText!,
                     errorBuilder,
                     resolvedErrorTextStyle,
                     errorPadding ?? const EdgeInsets.only(top: 6, left: 4),
                   ),
               ],
             ),
           );
         },
       );

  /// Private helper method to handle optional custom error layout rendering.
  static Widget _buildErrorWidget(
    BuildContext context,
    String errorText,
    Widget Function(BuildContext, String)? customBuilder,
    TextStyle style,
    EdgeInsetsGeometry padding,
  ) {
    if (customBuilder != null) {
      return customBuilder(context, errorText);
    }
    return Padding(
      padding: padding,
      child: Text(errorText, style: style),
    );
  }
}

/// Private container that tracks widget focus, handles the haptic triggers,
/// and executes the mathematical sine-wave shake animation.
class _FormFieldContainer extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enableShake;
  final bool enableHaptics;
  final Duration animationDuration;

  final Decoration? normalDecoration;
  final Decoration? errorDecoration;
  final Decoration? focusedDecoration;
  final Decoration? focusedErrorDecoration;
  final Decoration Function(bool isFocused) defaultNormalDecorationBuilder;
  final Decoration Function(bool isFocused) defaultErrorDecorationBuilder;
  final DecorationPlacement decorationPlacement;

  const _FormFieldContainer({
    required this.child,
    this.focusNode,
    required this.hasError,
    required this.enableShake,
    required this.enableHaptics,
    required this.animationDuration,
    this.normalDecoration,
    this.errorDecoration,
    this.focusedDecoration,
    this.focusedErrorDecoration,
    required this.defaultNormalDecorationBuilder,
    required this.defaultErrorDecorationBuilder,
    required this.decorationPlacement,
  });

  @override
  _FormFieldContainerState createState() => _FormFieldContainerState();
}

class _FormFieldContainerState extends State<_FormFieldContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    widget.focusNode?.addListener(_onFocusChange);
    _isFocused = widget.focusNode?.hasFocus ?? false;
  }

  @override
  void didUpdateWidget(covariant _FormFieldContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
      _isFocused = widget.focusNode?.hasFocus ?? false;
    }

    // Trigger error animation feedback when transitioning to an error state
    if (widget.hasError && !oldWidget.hasError) {
      if (widget.enableShake) {
        _shakeController.forward(from: 0.0);
      }
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode?.hasFocus ?? false;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _shakeController.dispose();
    super.dispose();
  }

  /// Calculates the current active decoration based on focus and error states.
  Decoration _resolveActiveDecoration() {
    if (widget.hasError) {
      if (_isFocused) {
        return widget.focusedErrorDecoration ?? widget.errorDecoration ?? widget.defaultErrorDecorationBuilder(true);
      }
      return widget.errorDecoration ?? widget.defaultErrorDecorationBuilder(false);
    } else {
      if (_isFocused) {
        return widget.focusedDecoration ?? widget.normalDecoration ?? widget.defaultNormalDecorationBuilder(true);
      }
      return widget.normalDecoration ?? widget.defaultNormalDecorationBuilder(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDecoration = _resolveActiveDecoration();

    Widget content;
    if (widget.decorationPlacement == DecorationPlacement.background) {
      content = AnimatedContainer(
        duration: widget.animationDuration,
        decoration: activeDecoration,
        child: widget.child,
      );
    } else {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedContainer(duration: widget.animationDuration, decoration: activeDecoration),
            ),
          ),
        ],
      );
    }

    // Wraps the built content with a horizontal mathematical shake transformation
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double progress = _shakeController.value;
        // Dampened sine wave formula for smooth decay shake effect
        final double offset = 8 * math.sin(progress * math.pi * 3.5) * (1 - progress);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: content,
    );
  }
}
