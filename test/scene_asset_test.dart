import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainDart = File('lib/main.dart').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  final scenePairs = RegExp(r"FilePair\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,?\s*\)")
      .allMatches(mainDart)
      .map((match) {
        return (background: match.group(1)!, frog: match.group(2)!);
      })
      .toList();

  final declaredAssets = RegExp(
    r'- assets/([^\s]+)',
  ).allMatches(pubspec).map((match) => match.group(1)!).toSet();

  test('scene catalog uses matching backgrounds for available frog scenes', () {
    final frogAssets = Directory('assets')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('_frog.flr'))
        .toSet();

    final expectedPairs = <({String background, String frog})>{};
    for (final frog in frogAssets) {
      final background = frog.replaceFirst('_frog.flr', '_bg.webp');
      if (File('assets/$background').existsSync()) {
        expectedPairs.add((background: background, frog: frog));
      }
    }

    final missingPairs = expectedPairs.difference(scenePairs.toSet());

    expect(missingPairs, isEmpty);
  });

  test('scene catalog assets exist and are declared in pubspec', () {
    for (final pair in scenePairs) {
      expect(File('assets/${pair.background}').existsSync(), isTrue);
      expect(File('assets/${pair.frog}').existsSync(), isTrue);
      expect(declaredAssets, contains(pair.background));
      expect(declaredAssets, contains(pair.frog));
    }
  });

  test('hill morning clear background is not a mushroom scene', () {
    final hillMorningClear = File(
      'assets/hill_morning_sunny_bg.webp',
    ).readAsBytesSync();
    final mushroomDayClear = File(
      'assets/mushroom_day_sunny_bg.webp',
    ).readAsBytesSync();

    expect(hillMorningClear, isNot(equals(mushroomDayClear)));
  });
}
