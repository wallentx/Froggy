import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggy/main.dart';
import 'package:froggy/weather_overlay.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('large android tv displays use performance mode', () {
    expect(
      shouldUseTvPerformanceMode(
        isAndroid: true,
        navigationMode: NavigationMode.directional,
        logicalSize: const Size(1920, 1080),
        devicePixelRatio: 2.0,
      ),
      isTrue,
    );
    expect(
      shouldUseTvPerformanceMode(
        isAndroid: false,
        navigationMode: NavigationMode.directional,
        logicalSize: const Size(1920, 1080),
        devicePixelRatio: 2.0,
      ),
      isFalse,
    );
  });

  testWidgets(
    'weather selector shows expanded options without horizontal scroll',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      await tester.tap(find.byTooltip('Weather Scenes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      for (final option in weatherOptions) {
        expect(find.text(option.label), findsOneWidget);
      }

      final horizontalPickers = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(horizontalPickers, findsNWidgets(2));
    },
  );

  testWidgets(
    'switching weather overlays in the same base scene updates view',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      await tester.tap(find.byTooltip('Weather Scenes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Snowy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        _lottieAssetNames(tester),
        contains('assets/animated_weather/tablet/showers_snow_background.json'),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Blizzard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        _lottieAssetNames(tester),
        contains('assets/animated_weather/tablet/blizzard_background.json'),
      );
    },
  );

  testWidgets('d-pad weather controls switch weather without touch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _lottieAssetNames(tester),
      contains('assets/animated_weather/tablet/haze_smoke_background.json'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _lottieAssetNames(tester),
      contains('assets/animated_weather/tablet/mostly_cloudy_background.json'),
    );
  });

  testWidgets(
    'android tv performance mode renders lightweight weather layers',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      expect(
        _lottieAssetNames(tester),
        isNot(
          contains(
            'assets/animated_weather/tablet/mostly_cloudy_background.json',
          ),
        ),
      );
      expect(
        _lottieAssetNames(tester),
        contains(
          'assets/animated_weather/tablet/mostly_cloudy_foreground.json',
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        _lottieAssetNames(tester),
        isNot(
          contains('assets/animated_weather/tablet/haze_smoke_background.json'),
        ),
      );
      expect(
        _lottieAssetNames(tester),
        contains('assets/animated_weather/tablet/haze_smoke_foreground.json'),
      );
    },
  );
}

List<String> _lottieAssetNames(WidgetTester tester) {
  return tester
      .widgetList<LottieBuilder>(find.byType(LottieBuilder))
      .map((widget) => widget.lottie)
      .whereType<AssetLottie>()
      .map((lottie) => lottie.assetName)
      .toList();
}
