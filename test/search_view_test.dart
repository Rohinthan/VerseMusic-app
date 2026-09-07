import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/library/album_model.dart';
import 'package:musicapp/core/library/artist_model.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/features/library/library_provider.dart';
import 'package:musicapp/features/search/search_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLibraryNotifierWithData extends LibraryNotifier {
  @override
  LibraryState build() {
    final song1 = Song(
      id: 'song-1',
      filePath: '/music/midnight_city.mp3',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: const Duration(seconds: 243),
    );

    final album1 = Album(
      id: 'album-1',
      title: 'Hurry Up, We\'re Dreaming',
      artist: 'M83',
      songCount: 1,
    );

    final artist1 = Artist(
      id: 'artist-1',
      name: 'M83',
      songCount: 1,
      albumCount: 1,
    );

    return LibraryState(
      isLoading: false,
      songs: [song1],
      albums: [album1],
      artists: [artist1],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestSearch() {
    return ProviderScope(
      overrides: [
        libraryNotifierProvider.overrideWith(FakeLibraryNotifierWithData.new),
      ],
      child: const MaterialApp(
        home: SearchView(),
      ),
    );
  }

  testWidgets('SearchView shows prompt initially and results upon query', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestSearch());
    await tester.pump();

    expect(find.text('Play what you love'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Midnight');
    await tester.pump();

    // Matching song should appear
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.text('SONGS (1)'), findsOneWidget);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('Play what you love'), findsOneWidget);
  });

  testWidgets('SearchView shows no results found for non-matching query', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestSearch());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'NonExistentTitleXYZ');
    await tester.pump();

    expect(find.text('No results found for "NonExistentTitleXYZ"'), findsOneWidget);
  });
}
