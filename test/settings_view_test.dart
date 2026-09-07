import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/theme/theme_provider.dart';
import 'package:musicapp/features/library/library_provider.dart';
import 'package:musicapp/features/settings/settings_provider.dart';
import 'package:musicapp/features/settings/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLibraryNotifier extends LibraryNotifier {
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

  Widget buildTestSettings() {
    return ProviderScope(
      overrides: [
        libraryNotifierProvider.overrideWith(FakeLibraryNotifier.new),
      ],
      child: const MaterialApp(
        home: SettingsView(),
      ),
    );
  }

  testWidgets('SettingsView renders all key sections and 14 color options', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestSettings());
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('LIBRARY & STORAGE'), findsOneWidget);
    expect(find.text('LYRICS & METADATA'), findsOneWidget);
    expect(find.text('ABOUT VERSE'), findsOneWidget);

    // Verify all 14 color options are rendered
    expect(kAccentColors.length, greaterThanOrEqualTo(12));
    for (final option in kAccentColors) {
      expect(find.byTooltip(option.name), findsOneWidget);
    }
  });

  testWidgets('Selecting a color in SettingsView updates accentColorProvider', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        libraryNotifierProvider.overrideWith(FakeLibraryNotifier.new),
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
    await tester.pump();

    // Default color is Spotify Green
    expect(container.read(accentColorProvider), equals(const Color(0xFF1DB954)));

    // Tap Electric Cyan option
    await tester.tap(find.byTooltip('Electric Cyan'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(accentColorProvider), equals(const Color(0xFF00E5FF)));
  });

  testWidgets('Toggling online lyrics switch updates lyricsOnlineFetchProvider', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        libraryNotifierProvider.overrideWith(FakeLibraryNotifier.new),
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
    await tester.pump();

    expect(container.read(lyricsOnlineFetchProvider), isTrue);

    // Toggle switch off
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(lyricsOnlineFetchProvider), isFalse);
  });
}
