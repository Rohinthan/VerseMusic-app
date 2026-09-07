import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/lyrics/lrc_parser.dart';
import 'package:musicapp/core/lyrics/lyrics_repository.dart';
import 'package:musicapp/features/lyrics/lyrics_provider.dart';
import 'package:musicapp/features/lyrics/views/synced_lyrics_view.dart';

class CustomLyricsNotifier extends LyricsNotifier {
  final LyricsState initialState;

  CustomLyricsNotifier(this.initialState);

  @override
  LyricsState build() {
    return initialState;
  }
}

void main() {
  Widget buildTestWidget(LyricsState state) {
    return ProviderScope(
      overrides: [
        lyricsNotifierProvider.overrideWith(() => CustomLyricsNotifier(state)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SyncedLyricsView(),
        ),
      ),
    );
  }

  testWidgets('SyncedLyricsView displays loading indicator when isLoading is true', (tester) async {
    await tester.pumpWidget(buildTestWidget(const LyricsState(isLoading: true)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Searching for lyrics...'), findsOneWidget);
  });

  testWidgets('SyncedLyricsView displays instrumental placeholder when isInstrumental is true', (tester) async {
    await tester.pumpWidget(buildTestWidget(const LyricsState(
      isLoading: false,
      isInstrumental: true,
      source: LyricsSource.lrclib,
    )));

    expect(find.text('Instrumental Track'), findsOneWidget);
    expect(find.text('This track contains no lyrics.'), findsOneWidget);
    expect(find.text('Search Again'), findsOneWidget);
  });

  testWidgets('SyncedLyricsView displays empty state when no lyrics found', (tester) async {
    await tester.pumpWidget(buildTestWidget(const LyricsState(
      isLoading: false,
      isInstrumental: false,
    )));

    expect(find.text('No Lyrics Available'), findsOneWidget);
    expect(find.text('Could not find lyrics locally or on LRCLIB.'), findsOneWidget);
    expect(find.text('Search Online Again'), findsOneWidget);
  });

  testWidgets('SyncedLyricsView displays plain text lyrics when unsynchronized', (tester) async {
    final parsed = LrcParser.parse('First line of plain lyric\nSecond line of plain lyric');
    await tester.pumpWidget(buildTestWidget(LyricsState(
      isLoading: false,
      lyrics: parsed,
      source: LyricsSource.lrclib,
    )));

    expect(find.text('First line of plain lyric'), findsOneWidget);
    expect(find.text('Second line of plain lyric'), findsOneWidget);
    expect(find.text('Synced via LRCLIB'), findsOneWidget);
  });

  testWidgets('SyncedLyricsView displays synced lyrics with active highlight', (tester) async {
    final parsed = LrcParser.parse('[00:01.00] Line 1\n[00:05.00] Line 2');
    await tester.pumpWidget(buildTestWidget(LyricsState(
      isLoading: false,
      lyrics: parsed,
      activeLineIndex: 0,
      source: LyricsSource.local,
      lyricsFilePath: '/music/song.lrc',
    )));

    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Line 2'), findsOneWidget);
    expect(find.text('Local .lrc file'), findsOneWidget);
  });
}
