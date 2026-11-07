#!/bin/bash
# YARG + VPX integration: see CMakeLists_plugin_Yarg.txt's own comment on
# why this exists. JUCE 7.0.12's createNSWindowSnapshot()
# (modules/juce_gui_basics/native/juce_Windowing_mac.mm) calls
# CGWindowListCreateImage unconditionally -- no modern ScreenCaptureKit
# alternative exists in this JUCE version at all (that was added later) --
# and the macOS 26 SDK this CI runner's Xcode bundles marks that API fully
# obsoleted, a hard compile error. Stubs the call out entirely rather than
# trying to route to a different code path that doesn't exist here:
# juceaide (the only thing that compiles this file as part of this
# project) never actually calls createNSWindowSnapshot() at runtime, so
# correctness of the stub does not matter, only compiling does.
#
# A real external script file, not an inline CMake PATCH_COMMAND string:
# several earlier attempts at the latter were lost to CMake/sed/bash
# quoting and escaping fights (a literal "//" comment breaking a
# "/"-delimited sed command; a standalone "" backup-suffix argument
# possibly being dropped by CMake's own list-argument handling) that a
# real file sidesteps entirely.
set -e

f="modules/juce_gui_basics/native/juce_Windowing_mac.mm"

if ! grep -q "CGWindowListCreateImage (CGRectNull," "$f"; then
   echo "vpx-yarg JUCE patch: expected CGWindowListCreateImage call not found in $f -- JUCE source may have changed, update this patch" >&2
   exit 1
fi

perl -0777 -pi -e 's#CGImageRef screenShot = CGWindowListCreateImage \(CGRectNull,.*?kCGWindowImageBoundsIgnoreFraming\);#CGImageRef screenShot = nullptr; // vpx-yarg: CGWindowListCreateImage is obsoleted on newer macOS SDKs, stubbed out -- see patch-juce-screenshot.sh#s' "$f"

if grep -q "CGWindowListCreateImage (CGRectNull," "$f"; then
   echo "vpx-yarg JUCE patch: perl ran but the call is still present -- patch had no effect" >&2
   exit 1
fi

echo "vpx-yarg JUCE patch: juce_Windowing_mac.mm patched successfully"
