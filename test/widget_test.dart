import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LocalMusicPlayerApp(),
      ),
    );

    expect(find.text('Local Music Player'), findsOneWidget);
  });
}
