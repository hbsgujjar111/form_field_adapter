## 1.1.0

### Added

* `disabledDecoration`, used when `enabled` is `false`. Shake and haptics are skipped for disabled fields.
* `autovalidateMode`, the correctly spelled replacement for `autoValidateMode`.
* `onChanged`, called when the value changes through user interaction or `didChange`.
* Pass-through of `onReset`, `forceErrorText` and `restorationId` to the underlying `FormField`.
* `shakeDuration` and `shakeOffset` to tune the shake animation.
* `ensureVisibleOnError` (off by default) to scroll the topmost failing field into view when an explicit validation fails. The scroll is instant when `MediaQuery.disableAnimations` is true.

### Changed

* Internal restructure: the code is split into `lib/src/` files. The public API and the import (`package:form_field_adapter/form_field_adapter.dart`) are unchanged.
* Added a library-level documentation comment.
* Shake and haptic feedback now repeat every time an explicit validation (for example `FormState.validate()`) fails again, not only when the field first becomes invalid. Errors that appear or stay while the user types do not repeat it.
* When `errorDecoration` is not set, the error state is derived from `focusedDecoration` / `normalDecoration`. A `BoxDecoration` with a `Border` or `BorderDirectional` has its visible sides recolored with the theme's error color. Previously the default bottom underline was used. A decoration without a border is reused unchanged.

### Deprecated

* `autoValidateMode`. Use `autovalidateMode` instead. It will be removed in 2.0.0.

### Example

* The demo form uses `ensureVisibleOnError`.

### Tests

* Flipped the repeated-feedback test and added tests for every addition above.

## 1.0.2

### Added

* Package test suite under `test/`.

### Changed

* Minimum SDK constraint is now `sdk: ^3.12.0` (previously `^3.11.5`).

### Fixed

* Default decorations now use a constant 1.5 px border width in every state, so focusing the field or showing an error no longer shifts the layout by about 1 px.
* The shake animation is skipped when `MediaQuery.disableAnimations` is true (haptics are unchanged).
* The error message is announced to screen readers as a live region.
* The default error padding is now directional (`start` instead of `left`), so it is correct in RTL layouts.

### Documentation

* Added API documentation (focus tracking, decoration resolution, `autoValidateMode` naming and default).
* Rewrote the README quick start and property table, and fixed the install version.

### Example

* Fixed the stale widget test.
* Added Android `INTERNET` and macOS `network.client` permissions needed by the demo's `NetworkImage`.
* Made the demo's focused-error border width constant.

### pub.dev

* Added `topics` and `screenshots`.

## 1.0.1

* Optimized example image assets and updated the example image asset name in README.md.

## 1.0.0

* Initial release