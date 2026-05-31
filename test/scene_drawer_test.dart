import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:froggy/main.dart';
import 'package:froggy/weather_overlay.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('scene location labels come from background filename prefixes', () {
    expect(
      sceneLocationLabelForBackgroundFile('fields_day_sunny_bg.webp'),
      'Fields',
    );
    expect(
      sceneLocationLabelForBackgroundFile('hill_day_sunny_bg.webp'),
      'Hills',
    );
    expect(
      sceneLocationLabelForBackgroundFile('mushroom_day_sunny_bg.webp'),
      'Home',
    );
    expect(
      sceneLocationLabelForBackgroundFile('city_park_day_sunny_bg.webp'),
      'City Park',
    );
  });

  test('location options include every parsed scene location once', () {
    expect(
      locationOptionsForScenes([
        ParsedScene(
          index: 0,
          location: 'Fields',
          time: 'Day',
          weather: 'Clear',
        ),
        ParsedScene(
          index: 1,
          location: 'Fields',
          time: 'Night',
          weather: 'Rainy',
        ),
        ParsedScene(index: 2, location: 'Hills', time: 'Day', weather: 'Clear'),
        ParsedScene(
          index: 3,
          location: 'City Park',
          time: 'Day',
          weather: 'Clear',
        ),
      ]),
      ['Fields', 'Hills', 'City Park'],
    );
  });

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

      await tester.pumpWidget(const MyApp(randomizeInitialScene: false));
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

      await tester.pumpWidget(const MyApp(randomizeInitialScene: false));
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

    await tester.pumpWidget(const MyApp(randomizeInitialScene: false));
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

  testWidgets('android tv performance mode renders no weather Lottie layers', (
    tester,
  ) async {
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
    expect(_lottieAssetNames(tester), isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _lottieAssetNames(tester),
      isNot(
        contains('assets/animated_weather/tablet/haze_smoke_background.json'),
      ),
    );
    expect(_lottieAssetNames(tester), isEmpty);
  });

  testWidgets(
    'android tv performance mode renders one scene without PageView',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(_sceneBackgroundAssetNames(tester), [
        'assets/fields_day_cloudy_bg.webp',
      ]);
      expect(_sceneBackgroundResizeSizes(tester), [const Size(1280, 1280)]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(_sceneBackgroundAssetNames(tester), [
        'assets/fields_day_hazy_bg.webp',
      ]);
      expect(_sceneBackgroundResizeSizes(tester), [const Size(1280, 1280)]);
    },
  );

  testWidgets(
    'android tv performance mode reuses clear frog asset across weather scenes',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      expect(_sceneBackgroundAssetNames(tester), [
        'assets/fields_day_cloudy_bg.webp',
      ]);
      expect(_flareActorFilenames(tester), [
        'assets/fields_day_sunny_frog.flr',
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(_sceneBackgroundAssetNames(tester), [
        'assets/fields_day_hazy_bg.webp',
      ]);
      expect(_flareActorFilenames(tester), [
        'assets/fields_day_sunny_frog.flr',
      ]);
    },
  );

  testWidgets(
    'android tv performance mode avoids broken home day and sunset frog assets',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      await _openTvMenu(tester);
      await tester.tap(find.byKey(const ValueKey('tv-menu-Home-option')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tv-menu-Clear-option')));
      await tester.pump();
      await tester.pump();

      expect(_sceneBackgroundAssetNames(tester), [
        'assets/mushroom_day_sunny_bg.webp',
      ]);
      expect(_flareActorFilenames(tester), [
        'assets/mushroom_day_cloudy_frog.flr',
      ]);

      await tester.tap(find.byKey(const ValueKey('tv-menu-Sunset-option')));
      await tester.pump();
      await tester.pump();

      expect(_sceneBackgroundAssetNames(tester), [
        'assets/mushroom_sunset_sunny_bg.webp',
      ]);
      expect(_flareActorFilenames(tester), [
        'assets/mushroom_sunset_cloudy_frog.flr',
      ]);
    },
  );

  testWidgets(
    'android tv performance mode clears image cache on scene changes',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      final imageCache = PaintingBinding.instance.imageCache;
      addTearDown(imageCache.clear);
      addTearDown(imageCache.clearLiveImages);

      final cacheKey = Object();
      final pendingImage = Completer<ImageInfo>();
      imageCache.putIfAbsent(
        cacheKey,
        () => OneFrameImageStreamCompleter(pendingImage.future),
      );
      expect(imageCache.statusForKey(cacheKey).pending, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(imageCache.statusForKey(cacheKey).pending, isFalse);
    },
  );

  testWidgets(
    'android tv performance mode hides touch controls and opens tv menu',
    (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
      );
      await tester.pump();

      expect(find.byTooltip('Weather Scenes'), findsNothing);

      await _openTvMenu(tester);

      expect(find.text('TV Scene Menu'), findsOneWidget);
      expect(find.text('Customize Weather Scene'), findsNothing);
      expect(find.text('Scenes'), findsNothing);
      expect(find.text('Fields'), findsOneWidget);
      expect(find.text('Hills'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Mushroom'), findsNothing);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Cloudy'), findsOneWidget);
      expect(find.text('Rainy'), findsOneWidget);
      expect(find.text('Snowy'), findsOneWidget);
      expect(find.text('Mostly Sunny'), findsNothing);
      expect(find.text('Blizzard'), findsNothing);
      expect(find.text('Fields - Day - Cloudy'), findsNothing);
    },
  );

  testWidgets('android tv menu exposes auto cycle controls', (tester) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await _openTvMenu(tester);

    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Every'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('Behavior'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
  });

  testWidgets('android tv menu opens with long select press only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();
    expect(find.text('TV Scene Menu'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(find.text('TV Scene Menu'), findsNothing);

    await _openTvMenu(tester);

    expect(find.text('TV Scene Menu'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('TV Scene Menu'), findsNothing);
  });

  testWidgets('android tv menu opens from select key repeat', (tester) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('TV Scene Menu'), findsOneWidget);
  });

  testWidgets('android tv menu handles d-pad selection and back dismissal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await _openTvMenu(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.byKey(const ValueKey('tv-menu-Hills-focused')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      _sceneBackgroundAssetNames(tester),
      contains('assets/hill_day_cloudy_bg.webp'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('TV Scene Menu'), findsNothing);
    expect(find.byType(AnimationScreen), findsOneWidget);
  });

  testWidgets('android tv scene changes unload old scene before loading next', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await _openTvMenu(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(
      _sceneBackgroundAssetNames(tester),
      isNot(contains('assets/fields_day_cloudy_bg.webp')),
    );
    expect(
      _sceneBackgroundAssetNames(tester),
      isNot(contains('assets/hill_day_cloudy_bg.webp')),
    );

    await tester.pump();

    expect(
      _sceneBackgroundAssetNames(tester),
      contains('assets/hill_day_cloudy_bg.webp'),
    );
  });

  testWidgets('android tv system back closes menu without exiting app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await _openTvMenu(tester);
    expect(find.text('TV Scene Menu'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('TV Scene Menu'), findsNothing);
    expect(find.byType(AnimationScreen), findsOneWidget);
  });

  testWidgets('android tv double select does not also trigger hello', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var helloRequests = 0;
    var behaviorRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AnimationScreen(
          forceTvPerformanceMode: true,
          onGreetingRequestForTesting: () => helloRequests++,
          onBehaviorChangeRequestForTesting: () => behaviorRequests++,
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 350));

    expect(helloRequests, 0);
    expect(behaviorRequests, 1);
  });

  testWidgets('android tv auto cycle alternates behavior and location', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var behaviorRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AnimationScreen(
          forceTvPerformanceMode: true,
          onBehaviorChangeRequestForTesting: () => behaviorRequests++,
        ),
      ),
    );
    await tester.pump();

    expect(_sceneBackgroundAssetNames(tester), [
      'assets/fields_day_cloudy_bg.webp',
    ]);

    await tester.pump(const Duration(minutes: 5, milliseconds: 1));
    await tester.pump();

    expect(behaviorRequests, 1);
    expect(_sceneBackgroundAssetNames(tester), [
      'assets/fields_day_cloudy_bg.webp',
    ]);

    await tester.pump(const Duration(minutes: 5, milliseconds: 1));
    await tester.pump();
    await tester.pump();

    expect(
      _sceneBackgroundAssetNames(tester),
      contains('assets/hill_day_cloudy_bg.webp'),
    );
  });

  testWidgets('android tv auto cycle can be disabled from the menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var behaviorRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AnimationScreen(
          forceTvPerformanceMode: true,
          onBehaviorChangeRequestForTesting: () => behaviorRequests++,
        ),
      ),
    );
    await tester.pump();

    await _openTvMenu(tester);
    await tester.tap(find.byKey(const ValueKey('tv-menu-Off-option')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    await tester.pump(const Duration(minutes: 5, milliseconds: 1));
    await tester.pump();

    expect(behaviorRequests, 0);
    expect(_sceneBackgroundAssetNames(tester), [
      'assets/fields_day_cloudy_bg.webp',
    ]);
  });

  testWidgets('android tv weather cycling uses only tv menu weather choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(_sceneBackgroundAssetNames(tester), [
      'assets/fields_day_sunny_bg.webp',
    ]);

    await _openTvMenu(tester);

    expect(
      find.byKey(const ValueKey('tv-menu-Clear-selected')),
      findsOneWidget,
    );
    expect(find.text('Mostly Sunny'), findsNothing);
  });

  testWidgets('android tv scene menu selects a scene from three selectors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    await _openTvMenu(tester);

    await tester.tap(find.byKey(const ValueKey('tv-menu-Home-option')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tv-menu-Night-option')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tv-menu-Clear-option')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(_sceneBackgroundAssetNames(tester), [
      'assets/mushroom_night_sunny_bg.webp',
    ]);
  });

  testWidgets('android tv performance mode prunes Flare cache immediately', (
    tester,
  ) async {
    final previousPruneDelay = FlareCache.pruneDelay;
    addTearDown(() => FlareCache.pruneDelay = previousPruneDelay);

    await tester.pumpWidget(
      const MaterialApp(home: AnimationScreen(forceTvPerformanceMode: true)),
    );
    await tester.pump();

    expect(FlareCache.pruneDelay, Duration.zero);
  });
}

List<String> _lottieAssetNames(WidgetTester tester) {
  return tester
      .widgetList<LottieBuilder>(find.byType(LottieBuilder))
      .map((widget) => widget.lottie)
      .whereType<AssetLottie>()
      .map((lottie) => lottie.assetName)
      .toList();
}

Future<void> _openTvMenu(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
  await tester.pump(const Duration(milliseconds: 650));
  await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

List<String> _sceneBackgroundAssetNames(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((widget) => _assetNameForImage(widget.image))
      .whereType<String>()
      .where((name) => name.endsWith('_bg.webp'))
      .toList();
}

List<String> _flareActorFilenames(WidgetTester tester) {
  return tester
      .widgetList<FlareActor>(find.byType(FlareActor))
      .map((widget) => widget.filename)
      .whereType<String>()
      .toList();
}

String? _assetNameForImage(ImageProvider image) {
  if (image is AssetImage) return image.assetName;
  if (image is ResizeImage) return _assetNameForImage(image.imageProvider);
  return null;
}

List<Size> _sceneBackgroundResizeSizes(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .where(
        (widget) =>
            _assetNameForImage(widget.image)?.endsWith('_bg.webp') ?? false,
      )
      .map((widget) => widget.image)
      .whereType<ResizeImage>()
      .map((image) => Size(image.width!.toDouble(), image.height!.toDouble()))
      .toList();
}
