import 'native_library_loader.dart';

/// Web / unsupported-platform [NativeLibraryLoader]. No `dart:ffi` is imported
/// here, so pulling this file into the web bundle keeps the bundle free of any
/// FFI dependency. It always reports the native library is unavailable.
class PlatformNativeLibraryLoader implements NativeLibraryLoader {
  const PlatformNativeLibraryLoader();

  @override
  bool get isAvailable => false;

  @override
  NativeWorldGen load() {
    throw UnsupportedError(
        'The native world-generation library is not available on this '
        'platform (web build).');
  }
}
