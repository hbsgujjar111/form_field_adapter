import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'reveal.dart';

/// Internal widget used by `FormFieldAdapter`: tracks focus, resolves the
/// active decoration and plays the shake and haptic feedback. Not exported.
class FormFieldContainer extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enabled;
  final int validationFailures;
  final bool enableShake;
  final bool enableHaptics;
  final bool disableAnimations;
  final bool ensureVisibleOnError;
  final Duration shakeDuration;
  final double shakeOffset;
  final Duration animationDuration;

  final Decoration? normalDecoration;
  final Decoration? errorDecoration;
  final Decoration? focusedDecoration;
  final Decoration? focusedErrorDecoration;
  final Decoration? disabledDecoration;
  final Decoration Function(bool isFocused) defaultNormalDecorationBuilder;
  final Decoration Function(bool isFocused) defaultErrorDecorationBuilder;
  final Decoration Function(Decoration base) deriveErrorDecoration;
  final DecorationPlacement decorationPlacement;

  const FormFieldContainer({
    super.key,
    required this.child,
    this.focusNode,
    required this.hasError,
    required this.enabled,
    required this.validationFailures,
    required this.enableShake,
    required this.enableHaptics,
    required this.disableAnimations,
    required this.ensureVisibleOnError,
    required this.shakeDuration,
    required this.shakeOffset,
    required this.animationDuration,
    this.normalDecoration,
    this.errorDecoration,
    this.focusedDecoration,
    this.focusedErrorDecoration,
    this.disabledDecoration,
    required this.defaultNormalDecorationBuilder,
    required this.defaultErrorDecorationBuilder,
    required this.deriveErrorDecoration,
    required this.decorationPlacement,
  });

  @override
  State<FormFieldContainer> createState() => _FormFieldContainerState();
}

class _FormFieldContainerState extends State<FormFieldContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: widget.shakeDuration,
    );

    widget.focusNode?.addListener(_onFocusChange);
    _isFocused = widget.focusNode?.hasFocus ?? false;
  }

  @override
  void didUpdateWidget(covariant FormFieldContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
      _isFocused = widget.focusNode?.hasFocus ?? false;
    }
    if (widget.shakeDuration != oldWidget.shakeDuration) {
      _shakeController.duration = widget.shakeDuration;
    }

    if (!widget.enabled || !widget.hasError) return;

    // Became invalid, or an explicit validation failed again.
    final bool revalidated =
        widget.validationFailures != oldWidget.validationFailures;
    if (!oldWidget.hasError || revalidated) {
      if (widget.enableShake && !widget.disableAnimations) {
        _shakeController.forward(from: 0.0);
      }
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }
    if (revalidated && widget.ensureVisibleOnError) {
      requestReveal(context);
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

  Decoration? _derived(Decoration? base) =>
      base == null ? null : widget.deriveErrorDecoration(base);

  Decoration _resolveActiveDecoration() {
    if (!widget.enabled && widget.disabledDecoration != null) {
      return widget.disabledDecoration!;
    }
    if (widget.hasError) {
      if (_isFocused) {
        return widget.focusedErrorDecoration ??
            widget.errorDecoration ??
            _derived(widget.focusedDecoration ?? widget.normalDecoration) ??
            widget.defaultErrorDecorationBuilder(true);
      }
      return widget.errorDecoration ??
          _derived(widget.normalDecoration) ??
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
            widget.shakeOffset *
            math.sin(progress * math.pi * 3.5) *
            (1 - progress);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: content,
    );
  }
}
