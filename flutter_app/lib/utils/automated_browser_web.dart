import 'dart:js_interop';

import 'dash0_config.dart' show isAutomatedUserAgent;

@JS('navigator')
external _Navigator? get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external JSBoolean? get webdriver;
  external JSString? get userAgent;
}

/// True when `navigator.webdriver` is set (WebDriver, Playwright, Puppeteer)
/// or the user agent is a headless browser. Never throws.
bool isAutomatedBrowser() {
  try {
    final navigator = _navigator;
    if (navigator == null) return false;
    if (navigator.webdriver?.toDart ?? false) return true;
    return isAutomatedUserAgent(navigator.userAgent?.toDart);
  } catch (_) {
    return false;
  }
}
