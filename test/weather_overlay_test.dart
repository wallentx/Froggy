import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:froggy/weather_overlay.dart';

void main() {
  test('lists additional weather overlay options with base scene fallback', () {
    expect(
      weatherOptions.map((option) => option.label),
      containsAll([
        'Mostly Sunny',
        'Drizzle',
        'Scattered Showers',
        'Storms',
        'Rain/Hail',
        'Flurries',
        'Heavy Snow',
        'Blowing Snow',
        'Blizzard',
        'Windy',
      ]),
    );
    expect(sceneWeatherForWeather('Drizzle'), 'Rainy');
    expect(sceneWeatherForWeather('Storms'), 'Rainy');
    expect(sceneWeatherForWeather('Blizzard'), 'Snowy');
    expect(sceneWeatherForWeather('Windy'), 'Clear');
  });

  test('maps app weather categories to tablet Lottie overlay assets', () {
    const basePath = 'assets/animated_weather/tablet';

    expect(
      overlayForWeather('Clear'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/sunny_background.json',
        foregroundAsset: '$basePath/sunny_foreground.json',
      ),
    );
    expect(
      overlayForWeather('Cloudy'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/mostly_cloudy_background.json',
        foregroundAsset: '$basePath/mostly_cloudy_foreground.json',
      ),
    );
    final mostlySunnyOverlay = overlayForWeather('Mostly Sunny');
    expect(mostlySunnyOverlay, isNotNull);
    expect(mostlySunnyOverlay!.backgroundAsset, isNull);
    expect(
      mostlySunnyOverlay.foregroundAsset,
      '$basePath/mostly_sunny_foreground.json',
    );
    expect(
      overlayForWeather('Hazy'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/haze_smoke_background.json',
        foregroundAsset: '$basePath/haze_smoke_foreground.json',
      ),
    );
    expect(
      overlayForWeather('Rainy'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/showers_rain_background.json',
        foregroundAsset: '$basePath/showers_rain_foreground.json',
      ),
    );
    expect(
      overlayForWeather('Snowy'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/showers_snow_background.json',
        foregroundAsset: '$basePath/showers_snow_foreground.json',
      ),
    );
    expect(
      overlayForWeather('Storms'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/strong_storms_v2_background.json',
        foregroundAsset: '$basePath/strong_storms_foreground.json',
      ),
    );
    expect(
      overlayForWeather('Blizzard'),
      const WeatherOverlay(
        backgroundAsset: '$basePath/blizzard_background.json',
        foregroundAsset: '$basePath/blizzard_foreground.json',
      ),
    );
  });

  test('all exposed weather overlay assets exist', () {
    for (final option in weatherOptions) {
      final backgroundAsset = option.overlay.backgroundAsset;
      if (backgroundAsset != null) {
        expect(
          File(backgroundAsset).existsSync(),
          isTrue,
          reason: '${option.label} background asset is missing',
        );
      }

      final foregroundAsset = option.overlay.foregroundAsset;
      if (foregroundAsset != null) {
        expect(
          File(foregroundAsset).existsSync(),
          isTrue,
          reason: '${option.label} foreground asset is missing',
        );
      }
    }
  });

  test('returns no overlay for unknown weather categories', () {
    expect(overlayForWeather('Foggy'), isNull);
  });

  test('tv performance overlays disable weather Lottie layers', () {
    for (final option in weatherOptions) {
      expect(
        overlayForWeather(option.label, performanceMode: true),
        const WeatherOverlay(backgroundAsset: null, foregroundAsset: null),
        reason: option.label,
      );
    }
  });
}
