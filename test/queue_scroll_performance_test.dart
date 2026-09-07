import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/features/playback/playback_provider.dart';
import 'package:musicapp/widgets/queue_sheet.dart';

void main() {
  testWidgets('QueueSheet scrolls smoothly without layout overflow on large playlist',
      (WidgetTester tester) async {
    // Generate a large playlist of 100 songs
    final songs = List.generate(
      100,
      (i) => Song(
        id: 'song_$i',
        filePath: '/music/song_$i.mp3',
        title: 'Track Title $i',
        artist: 'Artist $i',
        album: 'Album $i',
        duration: Duration(seconds: 120 + i),
      ),
    );

    final container = ProviderContainer();
    final notifier = container.read(playbackNotifierProvider.notifier);

    // Seed state with current song at index 0 and 99 upcoming songs
    notifier.playSong(songs.first, playlist: songs);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: QueueSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and ReorderableListView rendered
    expect(find.text('Play Queue'), findsOneWidget);
    expect(find.text('99 upcoming tracks'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);

    // Verify virtualization: offscreen items are NOT rendered
    expect(find.text('Track Title 95'), findsNothing);

    // Perform multiple fast scroll flings down and up to verify smooth virtualized performance
    final scrollFinder = find.byType(ReorderableListView);
    await tester.fling(scrollFinder, const Offset(0, -500), 2000);
    await tester.pumpAndSettle();

    await tester.fling(scrollFinder, const Offset(0, -800), 3000);
    await tester.pumpAndSettle();

    // Scroll back up
    await tester.fling(scrollFinder, const Offset(0, 1000), 3000);
    await tester.pumpAndSettle();

    // Verify no assertion error or exception was thrown during scrolling
    expect(tester.takeException(), isNull);
  });
}
