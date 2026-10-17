## 1.0.2

* Fixed: default decorations now use a constant 1.5 px border width in every state, so focusing the field or showing an error no longer shifts the layout by about 1 px.
* Fixed: the shake animation is skipped when `MediaQuery.disableAnimations` is true (haptics are unchanged).
* Fixed: the error message is announced to screen readers as a live region.
* Fixed: the default error padding is now directional (`start` instead of `left`), so it is correct in RTL layouts.
* Changed: minimum SDK constraint is now `sdk: ^3.12.0` (previously `^3.11.5`).
* Docs: added API documentation (focus tracking, decoration resolution, `autoValidateMode` naming and default), rewrote the README quick start and property table, and fixed the install version.
* Example: fixed the stale widget test, added Android `INTERNET` and macOS `network.client` permissions needed by the demo's `NetworkImage`, and made the demo's focused-error border width constant.
* Added a package test suite under `test/`.
* pub.dev: added `topics` and `screenshots`.

## 1.0.1

* Optimized example image assets and updated the example image asset name in README.md.


## 1.0.0 

* Initial release
