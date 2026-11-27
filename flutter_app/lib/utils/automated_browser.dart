/// Detects browsers driven by automation (Playwright, Puppeteer, Selenium,
/// headless Chrome). Always false outside the web.
library;

export 'automated_browser_stub.dart'
    if (dart.library.js_interop) 'automated_browser_web.dart';
