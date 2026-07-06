import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Defines where the state-based [Decoration] is drawn relative to the child widget.
enum DecorationPlacement {
  /// Wraps the child widget inside the decorated container.
  background,

  /// Overlays the decoration directly on top of the child widget using a [Stack].
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

/// A highly interactive, focus-aware custom [FormField] wrapper designed for Flutter.
class FormFieldAdapter<T> extends FormField<T> {
  FormFieldAdapter({
    super.key,
    super.initialValue,
    required Widget Function(FormFieldState<T> state) builder,
    super.validator,
    super.onSaved,
    AutovalidateMode? autoValidateMode,
    super.enabled,

    // Focus tracking
    FocusNode? focusNode,

    // State-based Custom Decorations
    Decoration? normalDecoration,
    Decoration? errorDecoration,
    Decoration? focusedDecoration,
    Decoration? focusedErrorDecoration,
    DecorationPlacement decorationPlacement = DecorationPlacement.background,

    // Feedback Customizations
    bool enableShake = true,
    bool enableHaptics = true,
    Duration animationDuration = const Duration(milliseconds: 200),

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
             autoValidateMode ?? AutovalidateMode.onUserInteraction,
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
                 color: focused
                     ? theme.colorScheme.primary
                     : theme.colorScheme.onSurface.withValues(alpha: .38),
                 width: focused ? 2.0 : 1.0,
               ),
             ),
           );

           Decoration defaultErrorDeco(bool focused) => BoxDecoration(
             border: Border(
               bottom: BorderSide(
                 color: resolvedErrorColor,
                 width: focused ? 2.0 : 1.0,
               ),
             ),
           );

           // Resolve the text alignment based on the column's cross axis alignment
           final resolvedErrorTextAlign =
               errorTextAlign ??
               (crossAxisAlignment == CrossAxisAlignment.center
                   ? TextAlign.center
                   : (crossAxisAlignment == CrossAxisAlignment.end
                         ? TextAlign.end
                         : TextAlign.start));

           final decoratedInput = _FormFieldContainer(
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
                   errorPadding ?? const EdgeInsets.only(bottom: 6, left: 4),
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
                   errorPadding ?? const EdgeInsets.only(top: 6, left: 4),
                   resolvedErrorTextAlign, // <-- Align the text
                 ),
             ],
           );
         },
       );

  static Widget _buildErrorWidget(
    BuildContext context,
    String errorText,
    Widget Function(BuildContext, String)? customBuilder,
    TextStyle style,
    EdgeInsetsGeometry padding,
    TextAlign textAlign,
  ) {
    if (customBuilder != null) {
      return customBuilder(context, errorText);
    }
    return Padding(
      padding: padding,
      child: Text(
        errorText,
        style: style,
        textAlign: textAlign, // <-- Apply text alignment
      ),
    );
  }
}

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

class _FormFieldContainerState extends State<_FormFieldContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

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

  Decoration _resolveActiveDecoration() {
    if (widget.hasError) {
      if (_isFocused) {
        return widget.focusedErrorDecoration ??
            widget.errorDecoration ??
            widget.defaultErrorDecorationBuilder(true);
      }
      return widget.errorDecoration ??
          widget.defaultErrorDecorationBuilder(false);
    } else {
      if (_isFocused) {
        return widget.focusedDecoration ??
            widget.normalDecoration ??
            widget.defaultNormalDecorationBuilder(true);
      }
      return widget.normalDecoration ??
          widget.defaultNormalDecorationBuilder(false);
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
              child: AnimatedContainer(
                duration: widget.animationDuration,
                decoration: activeDecoration,
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double progress = _shakeController.value;
        final double offset =
            8 * math.sin(progress * math.pi * 3.5) * (1 - progress);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: content,
    );
  }
}
