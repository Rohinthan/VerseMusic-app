import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/theme/wallpaper_provider.dart';
import 'package:musicapp/features/library/library_provider.dart';
import 'package:musicapp/features/settings/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLibraryNotifier extends LibraryNotifier {
  @override
  LibraryState build() {
    return const LibraryState(
      isLoading: false,
      songs: [],
      albums: [],
      artists: [],
      directories: ['/home/user/Music'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WallpaperSettings & WallpaperPreset Tests', () {
    test('Default settings are pure dark with standard opacity and blur', () {
      const settings = WallpaperSettings();
      expect(settings.presetId, 'none');
      expect(settings.customImagePath, isNull);
      expect(settings.opacity, 0.65);
      expect(settings.blur, 8.0);
      expect(settings.scale, 1.0);
      expect(settings.hasActiveWallpaper, isFalse);
    });

    test('hasActiveWallpaper returns true for non-none presets', () {
      const settings = WallpaperSettings(presetId: 'cosmic_nebula');
      expect(settings.hasActiveWallpaper, isTrue);
    });

    test('copyWith updates specific properties correctly', () {
      const settings = WallpaperSettings();
      final updated = settings.copyWith(
        presetId: 'cyberpunk_sunset',
        opacity: 0.40,
        blur: 15.0,
        scale: 1.25,
      );

      expect(updated.presetId, 'cyberpunk_sunset');
      expect(updated.opacity, 0.40);
      expect(updated.blur, 15.0);
      expect(updated.scale, 1.25);
    });

    test('kWallpaperPresets contains curated themes including Pure Dark and Dynamic Art', () {
      expect(kWallpaperPresets.length, greaterThanOrEqualTo(8));
      final ids = kWallpaperPresets.map((p) => p.id).toList();
      expect(ids, contains('none'));
      expect(ids, contains('dynamic_art'));
      expect(ids, contains('cosmic_nebula'));
      expect(ids, contains('cyberpunk_sunset'));
      expect(ids, contains('midnight_aurora'));
      expect(ids, contains('emerald_obsidian'));
      expect(ids, contains('sunset_horizon'));
      expect(ids, contains('custom'));
    });
  });

  group('WallpaperNotifier State Tests', () {
    test('WallpaperNotifier updates preset and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wallpaperProvider).presetId, 'none');

      await container.read(wallpaperProvider.notifier).setPreset('midnight_aurora');
      expect(container.read(wallpaperProvider).presetId, 'midnight_aurora');
      expect(container.read(wallpaperProvider).hasActiveWallpaper, isTrue);
    });

    test('WallpaperNotifier clamps opacity, blur, and scale correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wallpaperProvider.notifier);

      await notifier.setOpacity(1.5);
      expect(container.read(wallpaperProvider).opacity, 1.0);

      await notifier.setOpacity(-0.5);
      expect(container.read(wallpaperProvider).opacity, 0.0);

      await notifier.setBlur(50.0);
      expect(container.read(wallpaperProvider).blur, 30.0);

      await notifier.setScale(2.5);
      expect(container.read(wallpaperProvider).scale, 1.6);

      await notifier.setScale(0.5);
      expect(container.read(wallpaperProvider).scale, 0.8);
    });

    test('WallpaperNotifier reset restores default values', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wallpaperProvider.notifier);
      await notifier.setPreset('emerald_obsidian');
      await notifier.setOpacity(0.3);
      await notifier.setBlur(18.0);
      await notifier.setScale(1.4);

      expect(container.read(wallpaperProvider).presetId, 'emerald_obsidian');

      await notifier.reset();
      final resetState = container.read(wallpaperProvider);
      expect(resetState.presetId, 'none');
      expect(resetState.opacity, 0.65);
      expect(resetState.blur, 8.0);
      expect(resetState.scale, 1.0);
    });
  });

  group('WallpaperBackgroundWrapper Widget Tests', () {
    testWidgets('Renders child content when preset is none', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WallpaperBackgroundWrapper(
              child: Text('Content Under Test'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Content Under Test'), findsOneWidget);
    });

    testWidgets('Renders Stack with gradient when active wallpaper is set', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(wallpaperProvider.notifier).setPreset('cosmic_nebula');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WallpaperBackgroundWrapper(
              child: Text('Active Wallpaper Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Active Wallpaper Content'), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });
  });

  group('SettingsView Wallpaper Section UI Tests', () {
    testWidgets('SettingsView displays Wallpaper & Transparency section with presets', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          libraryNotifierProvider.overrideWith(_FakeLibraryNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACKGROUND WALLPAPER & TRANSPARENCY'), findsOneWidget);
      expect(find.text('Wallpaper Style'), findsOneWidget);
      expect(find.text('Dark Overlay Opacity'), findsOneWidget);
      expect(find.text('Background Blur'), findsOneWidget);
      expect(find.text('Wallpaper Zoom & Size'), findsOneWidget);

      // Verify preset buttons exist
      expect(find.text('Pure Dark'), findsWidgets);
      expect(find.text('Cosmic Nebula'), findsWidgets);
      expect(find.text('Cyberpunk Sunset'), findsWidgets);
    });

    testWidgets('Tapping a preset tile in SettingsView updates wallpaperProvider state', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          libraryNotifierProvider.overrideWith(_FakeLibraryNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Cyberpunk Sunset preset
      final cyberpunkFinder = find.text('Cyberpunk Sunset');
      expect(cyberpunkFinder, findsWidgets);
      await tester.tap(cyberpunkFinder.first);
      await tester.pumpAndSettle();

      expect(container.read(wallpaperProvider).presetId, 'cyberpunk_sunset');
    });
  });
}
