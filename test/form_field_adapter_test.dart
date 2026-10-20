import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_field_adapter/form_field_adapter.dart';

// Distinct colors so each state's decoration is unambiguous.
const _normalD = BoxDecoration(color: Color(0xFF000001));
const _focusedD = BoxDecoration(color: Color(0xFF000002));
const _errorD = BoxDecoration(color: Color(0xFF000003));
const _focusedErrorD = BoxDecoration(color: Color(0xFF000004));
const _disabledD = BoxDecoration(color: Color(0xFF000005));

const _inputKey = Key('input');
const _inputBox = SizedBox(key: _inputKey, width: 100, height: 40);

Widget _box(FormFieldState<int> state) => _inputBox;
String? _fail(int? value) => 'err';

final _adapter = find.byType(FormFieldAdapter<int>);
final List<MethodCall> _haptics = <MethodCall>[];

/// Mocks the platform channel so HapticFeedback calls are recorded, not lost.
void _recordHaptics(WidgetTester tester) {
  _haptics.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') _haptics.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<GlobalKey<FormState>> _pump(
  WidgetTester tester,
  Widget field, {
  bool disableAnimations = false,
  TextDirection? textDirection,
}) async {
  _recordHaptics(tester);
  final key = GlobalKey<FormState>();
  Widget body = Form(key: key, child: field);
  if (textDirection != null) {
    body = Directionality(textDirection: textDirection, child: body);
  }
  if (disableAnimations) {
    final inner = body;
    body = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: inner,
      ),
    );
  }
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  return key;
}

/// Fields separated (and followed) by 1500 px spacers inside a scroll view.
Future<GlobalKey<FormState>> _pumpScrolling(
  WidgetTester tester,
  List<Widget> fields, {
  bool disableAnimations = false,
}) async {
  _recordHaptics(tester);
  final key = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              children: [
                for (final f in fields) ...[const SizedBox(height: 1500), f],
                const SizedBox(height: 1500),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return key;
}

FormFieldAdapter<int> _scrollField(String id, {bool reveal = true}) =>
    FormFieldAdapter<int>(
      validator: _fail,
      ensureVisibleOnError: reveal,
      builder: (s) => SizedBox(key: Key(id), width: 100, height: 40),
    );

Future<void> _validate(WidgetTester tester, GlobalKey<FormState> key) async {
  key.currentState!.validate();
  await tester.pump();
}

AnimatedContainer _container(WidgetTester tester) => tester.widget(
  find.descendant(of: _adapter, matching: find.byType(AnimatedContainer)),
);

Decoration? _deco(WidgetTester tester) => _container(tester).decoration;

double _shakeDx(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: _adapter, matching: find.byType(Transform)),
    )
    .transform
    .getTranslation()
    .x;

ColorScheme _scheme(WidgetTester tester) =>
    Theme.of(tester.element(_adapter)).colorScheme;

void main() {
  group('rendering and error text', () {
    testWidgets('renders builder output and no error initially', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      expect(find.byKey(_inputKey), findsOneWidget);
      expect(find.text('err'), findsNothing);
    });

    testWidgets('valid field shows no error and validate() is true', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: (_) => null, builder: _box),
      );
      expect(key.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('err'), findsNothing);
    });

    testWidgets('error shown below input by default', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      expect(find.text('err'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('err')).dy,
        greaterThan(tester.getTopLeft(find.byKey(_inputKey)).dy),
      );
    });

    testWidgets('ErrorPosition.top shows error above input', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          errorPosition: ErrorPosition.top,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(
        tester.getTopLeft(find.text('err')).dy,
        lessThan(tester.getTopLeft(find.byKey(_inputKey)).dy),
      );
    });

    testWidgets('ErrorPosition.none hides error text but still flags error', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          errorPosition: ErrorPosition.none,
          errorDecoration: _errorD,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(find.text('err'), findsNothing);
      expect(_deco(tester), _errorD);
    });

    testWidgets('errorBuilder replaces the default error text', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          errorBuilder: (context, text) => Text('custom:$text'),
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(find.text('custom:err'), findsOneWidget);
      expect(find.text('err'), findsNothing);
    });

    testWidgets('default error style uses the theme error color', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      expect(
        tester.widget<Text>(find.text('err')).style?.color,
        _scheme(tester).error,
      );
    });

    testWidgets('errorTextStyle and errorPadding are applied', (tester) async {
      const style = TextStyle(fontSize: 21, color: Color(0xFF123456));
      const padding = EdgeInsets.only(top: 17);
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          errorTextStyle: style,
          errorPadding: padding,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(tester.widget<Text>(find.text('err')).style, style);
      final pad = find.ancestor(
        of: find.text('err'),
        matching: find.byType(Padding),
      );
      expect(tester.widget<Padding>(pad.first).padding, padding);
    });

    testWidgets('default bottom error padding is top:6 start:4', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      final pad = find.ancestor(
        of: find.text('err'),
        matching: find.byType(Padding),
      );
      expect(
        tester.widget<Padding>(pad.first).padding,
        const EdgeInsetsDirectional.only(top: 6, start: 4),
      );
    });

    testWidgets('error text alignment follows crossAxisAlignment', (
      tester,
    ) async {
      const cases = <CrossAxisAlignment, TextAlign>{
        CrossAxisAlignment.start: TextAlign.start,
        CrossAxisAlignment.center: TextAlign.center,
        CrossAxisAlignment.end: TextAlign.end,
      };
      for (final entry in cases.entries) {
        final key = await _pump(
          tester,
          FormFieldAdapter<int>(
            validator: _fail,
            crossAxisAlignment: entry.key,
            builder: _box,
          ),
        );
        await _validate(tester, key);
        expect(tester.widget<Text>(find.text('err')).textAlign, entry.value);
      }
    });

    testWidgets('explicit errorTextAlign wins over crossAxisAlignment', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          crossAxisAlignment: CrossAxisAlignment.center,
          errorTextAlign: TextAlign.end,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(tester.widget<Text>(find.text('err')).textAlign, TextAlign.end);
    });
    testWidgets('error text is a live region for screen readers', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      final live = find.ancestor(
        of: find.text('err'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
    });

    testWidgets('default error padding follows text direction', (tester) async {
      for (final dir in TextDirection.values) {
        final key = await _pump(
          tester,
          FormFieldAdapter<int>(validator: _fail, builder: _box),
          textDirection: dir,
        );
        await _validate(tester, key);
        final text = find.text('err');
        final input = find.byKey(_inputKey);
        if (dir == TextDirection.ltr) {
          expect(
            tester.getTopLeft(text).dx,
            closeTo(tester.getTopLeft(input).dx + 4, 0.01),
          );
        } else {
          expect(
            tester.getTopRight(text).dx,
            closeTo(tester.getTopRight(input).dx - 4, 0.01),
          );
        }
      }
    });
  });

  group('decoration resolution', () {
    testWidgets(
      'default decorations keep the same layout size in every state',
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        final key = await _pump(
          tester,
          FormFieldAdapter<int>(
            focusNode: node,
            validator: _fail,
            builder: (s) => Focus(focusNode: node, child: _inputBox),
          ),
        );
        final box = find.descendant(
          of: _adapter,
          matching: find.byType(AnimatedContainer),
        );
        final idle = tester.getSize(box);
        node.requestFocus();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(box), idle);
        await _validate(tester, key);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(box), idle);
      },
    );
    testWidgets('normal state uses normalDecoration', (tester) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(normalDecoration: _normalD, builder: _box),
      );
      expect(_deco(tester), _normalD);
    });

    testWidgets('default decorations use theme colors and widths', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          validator: _fail,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      final cs = _scheme(tester);

      expect(
        (_deco(tester)! as BoxDecoration).border,
        Border(
          bottom: BorderSide(
            color: cs.onSurface.withValues(alpha: .38),
            width: 1.5,
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      expect(
        (_deco(tester)! as BoxDecoration).border,
        Border(bottom: BorderSide(color: cs.primary, width: 1.5)),
      );

      await _validate(tester, key);
      expect(
        (_deco(tester)! as BoxDecoration).border,
        Border(bottom: BorderSide(color: cs.error, width: 1.5)),
      );
    });

    testWidgets('focus switches to focusedDecoration, falls back to normal', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          normalDecoration: _normalD,
          focusedDecoration: _focusedD,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(_deco(tester), _focusedD);
      node.unfocus();
      await tester.pump();
      expect(_deco(tester), _normalD);
    });

    testWidgets('focused without focusedDecoration keeps normalDecoration', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          normalDecoration: _normalD,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(_deco(tester), _normalD);
    });

    testWidgets('error uses errorDecoration; focused error uses '
        'focusedErrorDecoration, else errorDecoration', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          validator: _fail,
          normalDecoration: _normalD,
          errorDecoration: _errorD,
          focusedErrorDecoration: _focusedErrorD,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      await _validate(tester, key);
      expect(_deco(tester), _errorD);
      node.requestFocus();
      await tester.pump();
      expect(_deco(tester), _focusedErrorD);
    });

    testWidgets('focused error falls back to errorDecoration', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          validator: _fail,
          errorDecoration: _errorD,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      await _validate(tester, key);
      node.requestFocus();
      await tester.pump();
      expect(_deco(tester), _errorD);
    });

    testWidgets('foreground placement overlays decoration above the child', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          normalDecoration: _normalD,
          decorationPlacement: DecorationPlacement.foreground,
          builder: _box,
        ),
      );
      expect(
        find.descendant(of: _adapter, matching: find.byType(Stack)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _adapter, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(_deco(tester), _normalD);
    });

    testWidgets('animationDuration is forwarded to AnimatedContainer', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          animationDuration: const Duration(milliseconds: 123),
          builder: _box,
        ),
      );
      expect(_container(tester).duration, const Duration(milliseconds: 123));
    });

    testWidgets('swapping focusNode rewires the focus listener', (
      tester,
    ) async {
      _recordHaptics(tester);
      final a = FocusNode();
      final b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final key = GlobalKey<FormState>();
      Widget build(FocusNode n) => MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: FormFieldAdapter<int>(
              focusNode: n,
              normalDecoration: _normalD,
              focusedDecoration: _focusedD,
              builder: (s) => Focus(focusNode: n, child: _inputBox),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(a));
      await tester.pumpWidget(build(b));
      b.requestFocus();
      // Settle every frame, including the rebuild scheduled by the focus
      // listener, so a stale read cannot be mistaken for a bug.
      await tester.pumpAndSettle();
      expect(b.hasFocus, isTrue, reason: 'b was not attached to a Focus');
      expect(_deco(tester), _focusedD);
    });

    testWidgets('unmounting does not throw and leaves focus usable', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      node.requestFocus();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('form integration', () {
    testWidgets('default autovalidate is onUserInteraction', (tester) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: (v) => v == 1 ? 'bad' : null,
          builder: _box,
        ),
      );
      expect(find.text('bad'), findsNothing);
      tester.state<FormFieldState<int>>(_adapter).didChange(1);
      await tester.pump();
      expect(find.text('bad'), findsOneWidget);
    });

    testWidgets('autovalidateMode.disabled suppresses interaction validation', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          autovalidateMode: AutovalidateMode.disabled,
          validator: (v) => v == 1 ? 'bad' : null,
          builder: _box,
        ),
      );
      tester.state<FormFieldState<int>>(_adapter).didChange(1);
      await tester.pump();
      expect(find.text('bad'), findsNothing);
    });

    testWidgets('onSaved receives initialValue and latest value', (
      tester,
    ) async {
      int? saved;
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          initialValue: 4,
          autovalidateMode: AutovalidateMode.disabled,
          onSaved: (v) => saved = v,
          builder: _box,
        ),
      );
      key.currentState!.save();
      expect(saved, 4);
      tester.state<FormFieldState<int>>(_adapter).didChange(9);
      key.currentState!.save();
      expect(saved, 9);
    });

    testWidgets('reset clears error text and restores normal decoration', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          normalDecoration: _normalD,
          errorDecoration: _errorD,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(_deco(tester), _errorD);
      key.currentState!.reset();
      await tester.pump();
      expect(find.text('err'), findsNothing);
      expect(_deco(tester), _normalD);
    });

    testWidgets('empty-string error still flags error without throwing', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: (_) => '',
          normalDecoration: _normalD,
          errorDecoration: _errorD,
          builder: _box,
        ),
      );
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(_deco(tester), _errorD);
      expect(tester.takeException(), isNull);
    });
  });

  group('shake and haptics', () {
    testWidgets('no offset before any error', (tester) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      expect(_shakeDx(tester), closeTo(0, 1e-9));
    });

    testWidgets('failed validation shakes, then settles at zero', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_shakeDx(tester).abs(), greaterThan(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_shakeDx(tester), closeTo(0, 1e-9));
    });

    testWidgets('enableShake:false never moves the field', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          enableShake: false,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_shakeDx(tester), closeTo(0, 1e-9));
    });

    testWidgets('haptic fires once on first error', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      expect(_haptics, hasLength(1));
      expect(_haptics.single.arguments, 'HapticFeedbackType.lightImpact');
    });

    testWidgets('enableHaptics:false sends no haptic call', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          enableHaptics: false,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(_haptics, isEmpty);
    });

    testWidgets('reduce-motion skips the shake but keeps the haptic', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
        disableAnimations: true,
      );
      await _validate(tester, key);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_shakeDx(tester), closeTo(0, 1e-9));
      expect(_haptics, hasLength(1));
    });

    testWidgets('B1: every failed explicit validation repeats the feedback', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, builder: _box),
      );
      await _validate(tester, key);
      await _validate(tester, key);
      expect(_haptics, hasLength(2));
    });

    testWidgets('typing while an error is showing does not repeat feedback', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: (v) => (v ?? 0) < 3 ? 'err' : null,
          builder: _box,
        ),
      );
      final state = tester.state<FormFieldState<int>>(_adapter);
      state.didChange(1);
      await tester.pump();
      state.didChange(2);
      await tester.pump();
      expect(_haptics, hasLength(1));
    });

    testWidgets('feedback fires again after the error clears and returns', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: (v) => (v ?? 0) < 3 ? 'err' : null,
          builder: _box,
        ),
      );
      final state = tester.state<FormFieldState<int>>(_adapter);
      state.didChange(1);
      await tester.pump();
      expect(_haptics, hasLength(1));
      state.didChange(5);
      await tester.pump();
      state.didChange(2);
      await tester.pump();
      expect(_haptics, hasLength(2));
    });

    testWidgets(
      'error flow completes on every TargetPlatform',
      (tester) async {
        final key = await _pump(
          tester,
          FormFieldAdapter<int>(validator: _fail, builder: _box),
        );
        await _validate(tester, key);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('err'), findsOneWidget);
        expect(_haptics, hasLength(1));
        // On iOS, FormState.validate() delays a screen-reader announcement by
        // 1 s (Flutter framework behavior). Let it fire before the test ends.
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  });
  group('disabled fields', () {
    testWidgets('no feedback when disabled, but the error is still shown', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(enabled: false, validator: _fail, builder: _box),
      );
      tester.state<FormFieldState<int>>(_adapter).validate();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('err'), findsOneWidget);
      expect(_haptics, isEmpty);
      expect(_shakeDx(tester), closeTo(0, 1e-9));
    });

    testWidgets('disabledDecoration wins over every other state', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          enabled: false,
          validator: _fail,
          normalDecoration: _normalD,
          errorDecoration: _errorD,
          disabledDecoration: _disabledD,
          builder: _box,
        ),
      );
      expect(_deco(tester), _disabledD);
      tester.state<FormFieldState<int>>(_adapter).validate();
      await tester.pump();
      expect(_deco(tester), _disabledD);
    });

    testWidgets('disabledDecoration is ignored while enabled', (tester) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          normalDecoration: _normalD,
          disabledDecoration: _disabledD,
          builder: _box,
        ),
      );
      expect(_deco(tester), _normalD);
    });
  });

  group('derived error decoration', () {
    testWidgets(
      'recolors the border of normalDecoration, keeping shape/width',
      (tester) async {
        final key = await _pump(
          tester,
          FormFieldAdapter<int>(
            validator: _fail,
            normalDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF999999), width: 3),
            ),
            builder: _box,
          ),
        );
        await _validate(tester, key);
        final deco = _deco(tester)! as BoxDecoration;
        expect(deco.borderRadius, BorderRadius.circular(12));
        expect(deco.border, Border.all(color: _scheme(tester).error, width: 3));
      },
    );

    testWidgets('focused error derives from focusedDecoration', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          focusNode: node,
          validator: _fail,
          normalDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF999999), width: 1),
          ),
          focusedDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0000AA), width: 2),
          ),
          builder: (s) => Focus(focusNode: node, child: _inputBox),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await _validate(tester, key);
      final deco = _deco(tester)! as BoxDecoration;
      expect(deco.border, Border.all(color: _scheme(tester).error, width: 2));
    });

    testWidgets('BorderDirectional is recolored, empty sides stay empty', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          normalDecoration: const BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: Color(0xFF999999), width: 4),
              bottom: BorderSide(color: Color(0xFF999999)),
            ),
          ),
          builder: _box,
        ),
      );
      await _validate(tester, key);
      final error = _scheme(tester).error;
      expect(
        (_deco(tester)! as BoxDecoration).border,
        BorderDirectional(
          start: BorderSide(color: error, width: 4),
          bottom: BorderSide(color: error),
        ),
      );
    });

    testWidgets('a decoration without a border is reused unchanged', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          normalDecoration: _normalD,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(_deco(tester), _normalD);
    });
  });

  group('API additions', () {
    testWidgets('deprecated autoValidateMode still works; new name wins', (
      tester,
    ) async {
      await _pump(
        tester,
        FormFieldAdapter<int>(
          // ignore: deprecated_member_use_from_same_package
          autoValidateMode: AutovalidateMode.disabled,
          validator: (v) => v == 1 ? 'bad' : null,
          builder: _box,
        ),
      );
      tester.state<FormFieldState<int>>(_adapter).didChange(1);
      await tester.pump();
      expect(find.text('bad'), findsNothing);

      await _pump(
        tester,
        FormFieldAdapter<int>(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          // ignore: deprecated_member_use_from_same_package
          autoValidateMode: AutovalidateMode.disabled,
          validator: (v) => v == 1 ? 'bad' : null,
          builder: _box,
        ),
      );
      tester.state<FormFieldState<int>>(_adapter).didChange(1);
      await tester.pump();
      expect(find.text('bad'), findsOneWidget);
    });

    testWidgets('onChanged reports didChange but not reset', (tester) async {
      final seen = <int?>[];
      await _pump(
        tester,
        FormFieldAdapter<int>(onChanged: seen.add, builder: _box),
      );
      final state = tester.state<FormFieldState<int>>(_adapter);
      state.didChange(3);
      state.didChange(4);
      state.reset();
      await tester.pump();
      expect(seen, <int?>[3, 4]);
    });

    testWidgets('forceErrorText and onReset are forwarded', (tester) async {
      var resets = 0;
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          forceErrorText: 'server says no',
          onReset: () => resets++,
          builder: _box,
        ),
      );
      await _validate(tester, key);
      expect(find.text('server says no'), findsOneWidget);
      key.currentState!.reset();
      await tester.pump();
      expect(resets, 1);
    });

    testWidgets('shakeOffset scales the shake', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(validator: _fail, shakeOffset: 20, builder: _box),
      );
      await _validate(tester, key);
      await tester.pump(const Duration(milliseconds: 50));
      // Default offset 8 gives about 6.9 at this point; 20 gives about 17.
      expect(_shakeDx(tester).abs(), greaterThan(15));
    });

    testWidgets('shakeDuration stretches the shake', (tester) async {
      final key = await _pump(
        tester,
        FormFieldAdapter<int>(
          validator: _fail,
          shakeDuration: const Duration(seconds: 1),
          builder: _box,
        ),
      );
      await _validate(tester, key);
      await tester.pump(const Duration(milliseconds: 400));
      // With the default 350 ms the shake would already be over.
      expect(_shakeDx(tester).abs(), greaterThan(1));
      await tester.pump(const Duration(seconds: 2));
      expect(_shakeDx(tester), closeTo(0, 1e-9));
    });
  });

  group('ensureVisibleOnError', () {
    testWidgets('off by default: failed validation does not scroll', (
      tester,
    ) async {
      final key = await _pumpScrolling(tester, [
        _scrollField('first', reveal: false),
      ]);
      await _validate(tester, key);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        greaterThan(600),
      );
    });

    testWidgets('on: failed validation scrolls the field into view', (
      tester,
    ) async {
      final key = await _pumpScrolling(tester, [_scrollField('first')]);
      await _validate(tester, key);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        inInclusiveRange(0, 200),
      );
    });

    testWidgets('reduce motion: scrolls without an animation', (tester) async {
      final key = await _pumpScrolling(tester, [
        _scrollField('first'),
      ], disableAnimations: true);
      key.currentState!.validate();
      await tester.pump(); // rebuild, then the post-frame reveal jumps
      await tester.pump(); // lay out the new scroll position
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        inInclusiveRange(0, 200),
      );
    });

    testWidgets('animations on: scroll is still in progress after one frame', (
      tester,
    ) async {
      final key = await _pumpScrolling(tester, [_scrollField('first')]);
      key.currentState!.validate();
      await tester.pump();
      await tester.pump();
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        greaterThan(600),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        inInclusiveRange(0, 200),
      );
    });

    testWidgets('several invalid fields: the topmost one is revealed', (
      tester,
    ) async {
      final key = await _pumpScrolling(tester, [
        _scrollField('first'),
        _scrollField('second'),
      ]);
      await _validate(tester, key);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        inInclusiveRange(0, 200),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('second'))).dy,
        greaterThan(600),
      );
    });

    testWidgets('errors from typing do not scroll', (tester) async {
      await _pumpScrolling(tester, [_scrollField('first')]);
      tester
          .state<FormFieldState<int>>(find.byType(FormFieldAdapter<int>))
          .didChange(1);
      await tester.pumpAndSettle();
      expect(find.text('err'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        greaterThan(600),
      );
    });
  });
}
