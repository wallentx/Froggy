import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggy/main.dart';
import 'package:froggy/weather_overlay.dart';
import 'package:lottie/lottie.dart';

void main() {
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
}

List<String> _lottieAssetNames(WidgetTester tester) {
  return tester
      .widgetList<LottieBuilder>(find.byType(LottieBuilder))
      .map((widget) => widget.lottie)
      .whereType<AssetLottie>()
      .map((lottie) => lottie.assetName)
      .toList();
}
