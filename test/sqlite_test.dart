import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  test('SQLite database opens and executes queries via Flutter runner', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT
      )
    ''');

    await db.insert('songs', {
      'id': 'test-1',
      'title': 'Test Song',
      'artist': 'Test Artist',
    });

    final results = await db.query('songs');
    expect(results.length, equals(1));
    expect(results.first['title'], equals('Test Song'));
    expect(results.first['artist'], equals('Test Artist'));

    await db.close();
  });
}
