import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/audio/playback_state.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/core/notifications/desktop_notification_service.dart';
import 'package:musicapp/core/window/window_service.dart';
import 'package:musicapp/features/playback/playback_provider.dart';
import 'package:musicapp/features/playback/views/floating_pop_window_view.dart';
import 'package:musicapp/features/settings/settings_provider.dart';
import 'package:musicapp/features/settings/settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSong = Song(
    id: 'test_1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: const Duration(seconds: 230),
    filePath: '/path/to/starboy.mp3',
  );

  group('Desktop Notification Service Tests', () {
    test('DesktopNotificationService does not throw in test environment', () async {
      DesktopNotificationService.enabled = true;
      await expectLater(
        DesktopNotificationService.showSongNotification(testSong),
        completes,
      );

      DesktopNotificationService.enabled = false;
      await expectLater(
        DesktopNotificationService.showSongNotification(testSong),
        completes,
      );
      DesktopNotificationService.enabled = true;
    });

    test('DesktopNotificationNotifier toggles state and updates service', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(desktopNotificationEnabledProvider), isTrue);

      await container.read(desktopNotificationEnabledProvider.notifier).toggle(false);
      expect(container.read(desktopNotificationEnabledProvider), isFalse);
      expect(DesktopNotificationService.enabled, isFalse);

      await container.read(desktopNotificationEnabledProvider.notifier).toggle(true);
      expect(container.read(desktopNotificationEnabledProvider), isTrue);
      expect(DesktopNotificationService.enabled, isTrue);
    });
  });

  group('WindowService and isMiniWindowModeProvider Tests', () {
    test('isMiniWindowModeProvider defaults to false and can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isMiniWindowModeProvider), isFalse);

      container.read(isMiniWindowModeProvider.notifier).state = true;
      expect(container.read(isMiniWindowModeProvider), isTrue);

      container.read(isMiniWindowModeProvider.notifier).state = false;
      expect(container.read(isMiniWindowModeProvider), isFalse);
    });
  });

  group('FloatingPopWindowView Widget Tests', () {
    testWidgets('FloatingPopWindowView renders with song metadata and transport controls', (tester) async {
      final container = ProviderContainer(
        overrides: [
          playbackNotifierProvider.overrideWith(() => _MockPlaybackNotifier(testSong)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FloatingPopWindowView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VERSE MUSIC'), findsOneWidget);
      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);

      // Verify controls
      expect(find.byTooltip('Previous song'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Next song'), findsOneWidget);
      expect(find.byTooltip('Expand to full window'), findsOneWidget);
    });

    testWidgets('FloatingPopWindowView renders empty state cleanly when no song is playing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          playbackNotifierProvider.overrideWith(() => _MockEmptyPlaybackNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FloatingPopWindowView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No song playing'), findsOneWidget);
      expect(find.text('Select a song to start'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
    });
  });

  group('SettingsView Notifications Section Tests', () {
    testWidgets('SettingsView displays Notifications & Pop-up Window section', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Locate the section
      final sectionFinder = find.text('NOTIFICATIONS & POPUP WINDOW');
      expect(sectionFinder, findsOneWidget);

      expect(find.text('Desktop Song Notifications'), findsOneWidget);
      expect(find.text('Top Bar Notification Menu'), findsOneWidget);
    });
  });
}

class _MockPlaybackNotifier extends PlaybackNotifier {
  final Song song;
  _MockPlaybackNotifier(this.song);

  @override
  PlaybackState build() {
    return PlaybackState(
      currentSong: song,
      status: PlayerStatus.playing,
      position: const Duration(seconds: 45),
      duration: song.duration,
      playlist: [song],
      currentIndex: 0,
    );
  }
}

class _MockEmptyPlaybackNotifier extends PlaybackNotifier {
  @override
  PlaybackState build() {
    return const PlaybackState(
      currentSong: null,
      status: PlayerStatus.paused,
      position: Duration.zero,
      duration: Duration.zero,
      playlist: [],
      currentIndex: 0,
    );
  }
}
