import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Ensures LC_NUMERIC is set to "C" on Linux.
///
/// libmpv (underlying media_kit and just_audio_media_kit) strictly requires
/// LC_NUMERIC="C" to parse decimal points properly. Non-C locale causes
/// libmpv to abort or segfault immediately upon loading media.
void ensureLinuxAudioLocale() {
  if (!Platform.isLinux) return;
  try {
    final libc = ffi.DynamicLibrary.process();
    final setlocale = libc.lookupFunction<
        ffi.Pointer<ffi.Char> Function(ffi.Int32, ffi.Pointer<Utf8>),
        ffi.Pointer<ffi.Char> Function(int, ffi.Pointer<Utf8>)>('setlocale');
    final cStr = 'C'.toNativeUtf8();
    // 1 is LC_NUMERIC in GNU C library
    setlocale(1, cStr);
    calloc.free(cStr);
  } catch (e) {
    debugPrint('Warning: Failed to set Linux LC_NUMERIC: $e');
  }
}
