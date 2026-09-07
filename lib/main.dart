import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'core/audio/linux_locale.dart';
import 'core/theme/theme_provider.dart';
import 'features/shell/main_shell.dart';

void main() {
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
      home: const MainShell(),
    );
  }
}
