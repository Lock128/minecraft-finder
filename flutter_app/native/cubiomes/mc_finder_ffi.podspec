#
# mc_finder_ffi.podspec
#
# CocoaPods spec compiling the vendored Cubiomes core + FFI shim into the iOS
# and macOS app binaries. Because the C sources are compiled directly into the
# Runner, the symbols live in the app process and NativeFfiBackend resolves them
# via DynamicLibrary.process() (no separate dylib to ship or sign).
#
# Add to ios/Podfile and macos/Podfile inside the Runner target:
#
#     pod 'mc_finder_ffi', :path => '../native/cubiomes'
#
Pod::Spec.new do |s|
  s.name             = 'mc_finder_ffi'
  s.version          = '1.0.0'
  s.summary          = 'Vendored Cubiomes + flat FFI shim for seed-accurate worldgen.'
  s.description      = <<-DESC
  A thin C shim (mcf_find_structures / mcf_find_ores / mcf_get_biome) over a
  vendored subset of Cubiomes, compiled into the app so dart:ffi can resolve the
  symbols from the running process on iOS and macOS.
                       DESC
  s.homepage         = 'https://github.com/Cubitect/cubiomes'
  s.license          = { :type => 'MIT' }
  s.author           = { 'minecraft-finder' => 'noreply@example.com' }
  s.source           = { :path => '.' }

  s.source_files     = 'cubiomes_core.c', 'mc_finder_ffi.c', '*.h'
  s.public_header_files = 'mc_finder_ffi.h', 'cubiomes_core.h'
  s.requires_arc     = false

  s.ios.deployment_target  = '12.0'
  s.osx.deployment_target  = '10.14'

  # Keep the shim symbols visible so DynamicLibrary.process() can find them.
  s.pod_target_xcconfig = {
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'NO',
    'DEFINES_MODULE' => 'YES',
  }
end
