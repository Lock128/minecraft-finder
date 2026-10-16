# Native build wiring per platform

The vendored Cubiomes core + FFI shim (`CMakeLists.txt`, `cubiomes_core.*`,
`mc_finder_ffi.*`) is consumed by every platform. The library name is stable
(`mc_finder_ffi`) so `NativeFfiBackend` resolves it uniformly.

## Android (Gradle externalNativeBuild)

Wired in `android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        externalNativeBuild { cmake { arguments += "-DANDROID_STL=none" } }
        ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64") }
    }
    externalNativeBuild {
        cmake {
            path = file("../../native/cubiomes/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}
```

Gradle produces one `libmc_finder_ffi.so` per ABI, packaged into the APK/AAB.
`NativeFfiBackend` loads it with `DynamicLibrary.open('libmc_finder_ffi.so')`.

## iOS / macOS (CocoaPods + Xcode compile phase)

`mc_finder_ffi.podspec` compiles the C sources directly into the Runner target,
so the symbols live in the app process. Add to `ios/Podfile` and `macos/Podfile`
inside the `Runner` target:

```ruby
pod 'mc_finder_ffi', :path => '../native/cubiomes'
```

Because the shim is linked into the app binary, `NativeFfiBackend` resolves the
symbols with `DynamicLibrary.process()` (no dylib to ship or codesign).

## Windows / Linux (CMake desktop runner)

When the desktop platform folders are enabled (`flutter create --platforms=
windows,linux .`), add the shared project to the generated runner CMake:

```cmake
# windows/runner/CMakeLists.txt  /  linux/CMakeLists.txt
add_subdirectory("../native/cubiomes" "mc_finder_ffi")

# Bundle the shared library next to the executable so DynamicLibrary.open can
# find it at runtime.
install(TARGETS mc_finder_ffi
        RUNTIME DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"   # Windows .dll
        LIBRARY DESTINATION "${INSTALL_BUNDLE_LIB_DIR}")  # Linux .so
```

`NativeFfiBackend` loads `mc_finder_ffi.dll` (Windows) or
`libmc_finder_ffi.so` (Linux) via `DynamicLibrary.open`.

## Host smoke build (Linux x64)

The CI job `native-smoke` (see `.github/workflows/native-smoke.yml`) and local
development can validate the shim on the Linux host:

```sh
cd native/cubiomes
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
# then dlopen-check the resolved symbols
```
