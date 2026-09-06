import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  library,
  search,
  settings,
}

enum LibraryTab {
  songs,
  albums,
  artists,
}

class NavigationState {
  final AppTab currentTab;
  final LibraryTab libraryTab;

  const NavigationState({
    this.currentTab = AppTab.library,
    this.libraryTab = LibraryTab.songs,
  });

  NavigationState copyWith({
    AppTab? currentTab,
    LibraryTab? libraryTab,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      libraryTab: libraryTab ?? this.libraryTab,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return const NavigationState();
  }

  void setTab(AppTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void setLibraryTab(LibraryTab tab) {
    state = state.copyWith(libraryTab: tab);
  }
}

final navigationNotifierProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
  NavigationNotifier.new,
);
