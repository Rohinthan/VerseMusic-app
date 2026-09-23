import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'core/audio/linux_locale.dart';
import 'core/theme/theme_provider.dart';
import 'core/window/window_service.dart';
import 'features/playback/views/floating_pop_window_view.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure LC_NUMERIC is "C" on Linux before libmpv/media_kit initializes
  ensureLinuxAudioLocale();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CAUGHT_FLUTTER_ERROR: ${details.exceptionAsString()}');
    debugPrint('CAUGHT_FLUTTER_STACK: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('CAUGHT_PLATFORM_ERROR: $error');
    debugPrint('CAUGHT_PLATFORM_STACK: $stack');
    return true; // prevent process exit
  };

  // Initialize Linux desktop audio backend via libmpv
  if (Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: false,
      android: false,
      iOS: false,
      macOS: false,
    );
  }

  // Initialize desktop window manager for floating pop-up player support
  if (!Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
    } catch (e) {
      debugPrint('WindowManager init: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: VerseMusicApp(),
    ),
  );
}

class VerseMusicApp extends ConsumerWidget {
  const VerseMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final isMiniWindow = ref.watch(isMiniWindowModeProvider);

    return MaterialApp(
      title: 'Verse Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor.withAlpha(200),
          surface: const Color(0xFF181818),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: isMiniWindow ? const FloatingPopWindowView() : const MainShell(),
    );
  }
}
