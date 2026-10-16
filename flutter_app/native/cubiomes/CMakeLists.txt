#
# CMakeLists.txt for the vendored Cubiomes core + the flat FFI shim.
#
# Builds `mc_finder_ffi` as both a shared library (.so / .dll / .dylib) and a
# static library (.a) so every target platform can consume it:
#   - Android: invoked by Gradle externalNativeBuild (one .so per ABI).
#   - iOS/macOS: consumed as a static lib via the CocoaPods/Xcode phase.
#   - Windows/Linux: produces a .dll / .so loaded by DynamicLibrary.open.
#
# The library name is kept stable ("mc_finder_ffi") so NativeFfiBackend can
# resolve it uniformly across platforms.
cmake_minimum_required(VERSION 3.10)

project(mc_finder_ffi C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_VISIBILITY_PRESET hidden)

set(MCF_SOURCES
    cubiomes_core.c
    mc_finder_ffi.c
)

# Shared library — the primary artifact for runtime DynamicLibrary.open.
add_library(mc_finder_ffi SHARED ${MCF_SOURCES})
target_include_directories(mc_finder_ffi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Static library — used by the iOS/macOS CocoaPods/Xcode integration, which
# links the archive into the app binary (resolved via DynamicLibrary.process).
add_library(mc_finder_ffi_static STATIC ${MCF_SOURCES})
target_include_directories(mc_finder_ffi_static
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(mc_finder_ffi_static PROPERTIES OUTPUT_NAME mc_finder_ffi)

if(NOT WIN32)
  target_link_libraries(mc_finder_ffi m)
  target_link_libraries(mc_finder_ffi_static m)
endif()

# Keep math library symbols out of the stripped exports but preserve the shim
# API visibility (set explicitly in the header via MCF_EXPORT).
set_target_properties(mc_finder_ffi PROPERTIES
    C_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON)
