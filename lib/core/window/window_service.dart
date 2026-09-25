import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class MiniWindowModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setMini(bool val) => state = val;
  void toggle() => state = !state;
}

/// Provider for whether the app is currently in Floating Mini Pop-up Window mode.
final isMiniWindowModeProvider =
    NotifierProvider<MiniWindowModeNotifier, bool>(MiniWindowModeNotifier.new);

/// Manages desktop window resizing and always-on-top behavior for the mini pop-up player.
class WindowService {
  static Size? _previousSize;
  static Offset? _previousPosition;

  static bool get isDesktop =>
      !Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  /// Enters floating pop-up window mode (compact always-on-top window).
  static Future<void> enterMiniWindowMode(WidgetRef ref) async {
    ref.read(isMiniWindowModeProvider.notifier).setMini(true);

    if (!isDesktop) return;

    try {
      _previousSize = await windowManager.getSize();
      _previousPosition = await windowManager.getPosition();

      await windowManager.setMinimumSize(const Size(340, 120));
      await windowManager.setMaximumSize(const Size(520, 180));
      await windowManager.setSize(const Size(400, 142));
      await windowManager.setAlwaysOnTop(true);
    } catch (e) {
      debugPrint('Error entering mini window mode: $e');
    }
  }

  /// Exits floating pop-up window mode and restores the normal application window size.
  static Future<void> exitMiniWindowMode(WidgetRef ref) async {
    ref.read(isMiniWindowModeProvider.notifier).setMini(false);

    if (!isDesktop) return;

    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(400, 500));
      await windowManager.setMaximumSize(Size.infinite);

      final targetSize = _previousSize ?? const Size(1280, 720);
      await windowManager.setSize(targetSize);

      if (_previousPosition != null) {
        await windowManager.setPosition(_previousPosition!);
      }
    } catch (e) {
      debugPrint('Error exiting mini window mode: $e');
    }
  }

  /// Toggles between full application window and floating pop-up window mode.
  static Future<void> toggleMiniWindowMode(WidgetRef ref) async {
    final isMini = ref.read(isMiniWindowModeProvider);
    if (isMini) {
      await exitMiniWindowMode(ref);
    } else {
      await enterMiniWindowMode(ref);
    }
  }
}
