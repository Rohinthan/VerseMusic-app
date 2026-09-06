import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/features/navigation/navigation_provider.dart';

void main() {
  group('NavigationProvider Tests', () {
    test('initial state has default library tab and songs subtab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final navState = container.read(navigationNotifierProvider);
      expect(navState.currentTab, equals(AppTab.library));
      expect(navState.libraryTab, equals(LibraryTab.songs));
    });

    test('setTab switches main tab correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationNotifierProvider.notifier);

      notifier.setTab(AppTab.search);
      expect(container.read(navigationNotifierProvider).currentTab, equals(AppTab.search));

      notifier.setTab(AppTab.settings);
      expect(container.read(navigationNotifierProvider).currentTab, equals(AppTab.settings));

      notifier.setTab(AppTab.library);
      expect(container.read(navigationNotifierProvider).currentTab, equals(AppTab.library));
    });

    test('setLibraryTab switches sub-tabs correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationNotifierProvider.notifier);

      notifier.setLibraryTab(LibraryTab.albums);
      expect(container.read(navigationNotifierProvider).libraryTab, equals(LibraryTab.albums));

      notifier.setLibraryTab(LibraryTab.artists);
      expect(container.read(navigationNotifierProvider).libraryTab, equals(LibraryTab.artists));

      notifier.setLibraryTab(LibraryTab.songs);
      expect(container.read(navigationNotifierProvider).libraryTab, equals(LibraryTab.songs));
    });

    test('NavigationState copyWith creates updated instances properly', () {
      const state = NavigationState();
      final updated = state.copyWith(
        currentTab: AppTab.settings,
        libraryTab: LibraryTab.albums,
      );

      expect(updated.currentTab, equals(AppTab.settings));
      expect(updated.libraryTab, equals(LibraryTab.albums));
    });
  });
}
