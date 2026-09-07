import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/lyrics/lrc_parser.dart';

void main() {
  group('LRC Parser Tests', () {
    test('parses empty or whitespace-only content gracefully', () {
      final emptyResult = LrcParser.parse('');
      expect(emptyResult.isEmpty, isTrue);
      expect(emptyResult.isSynced, isFalse);
      expect(emptyResult.lines, isEmpty);

      final wsResult = LrcParser.parse('   \n\n\t  ');
      expect(wsResult.isEmpty, isTrue);
    });

    test('parses standard timestamped LRC with metadata tags', () {
      const lrcContent = '''
[ti:Never Gonna Give You Up]
[ar:Rick Astley]
[al:Whenever You Need Somebody]
[00:18.50]We're no strangers to love
[00:22.80]You know the rules and so do I
[00:27.10]A full commitment's what I'm thinking of
[00:31.40]You wouldn't get this from any other guy
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.lines.length, equals(4));
      expect(lyrics.tags['ti'], equals('Never Gonna Give You Up'));
      expect(lyrics.tags['ar'], equals('Rick Astley'));
      expect(lyrics.tags['al'], equals('Whenever You Need Somebody'));

      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 18, milliseconds: 500)));
      expect(lyrics.lines[0].text, equals("We're no strangers to love"));

      expect(lyrics.lines[1].timestamp, equals(const Duration(seconds: 22, milliseconds: 800)));
      expect(lyrics.lines[1].text, equals('You know the rules and so do I'));
    });

    test('parses multi-timestamp lines correctly', () {
      const lrcContent = '''
[00:10.00][00:30.00]Chorus line repeated twice
[00:20.00]Verse line in between
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.lines.length, equals(3));
      // Should be sorted chronologically: 10s, 20s, 30s
      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 10)));
      expect(lyrics.lines[0].text, equals('Chorus line repeated twice'));

      expect(lyrics.lines[1].timestamp, equals(const Duration(seconds: 20)));
      expect(lyrics.lines[1].text, equals('Verse line in between'));

      expect(lyrics.lines[2].timestamp, equals(const Duration(seconds: 30)));
      expect(lyrics.lines[2].text, equals('Chorus line repeated twice'));
    });

    test('applies global [offset] tag properly', () {
      const lrcContent = '''
[offset:500]
[00:10.00]Line with +500ms offset
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.lines.length, equals(1));
      // 10000ms + 500ms = 10500ms
      expect(lyrics.lines[0].timestamp, equals(const Duration(milliseconds: 10500)));
    });

    test('handles fractional timestamps in 2-digit and 3-digit forms', () {
      const lrcContent = '''
[01:05.1]Single digit tenth
[01:10.25]Two digit hundredth
[01:15.375]Three digit millisecond
''';

      final lyrics = LrcParser.parse(lrcContent);
      expect(lyrics.lines[0].timestamp, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 100)));
      expect(lyrics.lines[1].timestamp, equals(const Duration(minutes: 1, seconds: 10, milliseconds: 250)));
      expect(lyrics.lines[2].timestamp, equals(const Duration(minutes: 1, seconds: 15, milliseconds: 375)));
    });

    test('parses plain unsynchronized lyrics without error', () {
      const plainContent = '''
Just a plain lyric line 1
Another line without timestamps
Final line of the song
''';

      final lyrics = LrcParser.parse(plainContent);
      expect(lyrics.isSynced, isFalse);
      expect(lyrics.lines.length, equals(3));
      expect(lyrics.lines[0].text, equals('Just a plain lyric line 1'));
      expect(lyrics.lines[1].text, equals('Another line without timestamps'));
    });
  });

  group('Active Line Lookup (Binary Search) Tests', () {
    final lyrics = LrcParser.parse('''
[00:10.00]Line 0 (10s)
[00:20.00]Line 1 (20s)
[00:30.00]Line 2 (30s)
[00:40.00]Line 3 (40s)
''');

    test('returns -1 when playback position is before the first line', () {
      expect(lyrics.getActiveLineIndex(Duration.zero), equals(-1));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 5)), equals(-1));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 9, milliseconds: 999)), equals(-1));
    });

    test('returns 0 when position matches or is between line 0 and line 1', () {
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 10)), equals(0));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 15)), equals(0));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 19, milliseconds: 999)), equals(0));
    });

    test('returns correct index in middle and end of track', () {
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 20)), equals(1));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 25)), equals(1));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 30)), equals(2));
      expect(lyrics.getActiveLineIndex(const Duration(seconds: 40)), equals(3));
      expect(lyrics.getActiveLineIndex(const Duration(minutes: 5)), equals(3));
    });
  });
}
