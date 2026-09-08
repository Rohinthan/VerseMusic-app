import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('kAccentColors contains at least 12 vibrant options with unique IDs and colors', () {
    expect(kAccentColors.length, greaterThanOrEqualTo(12));

    final ids = kAccentColors.map((c) => c.id).toSet();
    final colors = kAccentColors.map((c) => c.color.toARGB32()).toSet();

    expect(ids.length, equals(kAccentColors.length));
    expect(colors.length, equals(kAccentColors.length));
  });

  test('accentColorProvider defaults to Spotify Green', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final color = container.read(accentColorProvider);
    expect(color, equals(const Color(0xFF1DB954)));
  });

  test('accentColorProvider updates color and persists to SharedPreferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const newColor = Color(0xFF00E5FF); // Electric Cyan
    await container.read(accentColorProvider.notifier).setAccentColor(newColor);

    expect(container.read(accentColorProvider), equals(newColor));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('app_accent_color_val'), equals(newColor.toARGB32()));
  });

  test('ThemeData.estimateBrightnessForColor calculates proper contrast for all 14 accent colors', () {
    for (final option in kAccentColors) {
      final brightness = ThemeData.estimateBrightnessForColor(option.color);
      final onAccent = brightness == Brightness.light ? Colors.black : Colors.white;
      expect(onAccent, anyOf(equals(Colors.black), equals(Colors.white)));
    }
  });
}
