class WeatherOverlay {
  final String? backgroundAsset;
  final String? foregroundAsset;

  const WeatherOverlay({
    required this.backgroundAsset,
    required this.foregroundAsset,
  });

  @override
  bool operator ==(Object other) {
    return other is WeatherOverlay &&
        backgroundAsset == other.backgroundAsset &&
        foregroundAsset == other.foregroundAsset;
  }

  @override
  int get hashCode => Object.hash(backgroundAsset, foregroundAsset);

  bool get isEmpty => backgroundAsset == null && foregroundAsset == null;
}

class WeatherOption {
  final String label;
  final String sceneWeather;
  final WeatherOverlay overlay;

  const WeatherOption({
    required this.label,
    required this.sceneWeather,
    required this.overlay,
  });
}

const String weatherOverlayBasePath = 'assets/animated_weather/tablet';

const List<WeatherOption> weatherOptions = [
  WeatherOption(
    label: 'Clear',
    sceneWeather: 'Clear',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/sunny_background.json',
      foregroundAsset: '$weatherOverlayBasePath/sunny_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Mostly Sunny',
    sceneWeather: 'Clear',
    overlay: WeatherOverlay(
      backgroundAsset: null,
      foregroundAsset: '$weatherOverlayBasePath/mostly_sunny_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Cloudy',
    sceneWeather: 'Cloudy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/mostly_cloudy_background.json',
      foregroundAsset: '$weatherOverlayBasePath/mostly_cloudy_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Hazy',
    sceneWeather: 'Hazy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/haze_smoke_background.json',
      foregroundAsset: '$weatherOverlayBasePath/haze_smoke_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Windy',
    sceneWeather: 'Clear',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/windy_breezy_background.json',
      foregroundAsset: '$weatherOverlayBasePath/windy_breezy_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Rainy',
    sceneWeather: 'Rainy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/showers_rain_background.json',
      foregroundAsset: '$weatherOverlayBasePath/showers_rain_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Drizzle',
    sceneWeather: 'Rainy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/drizzle_background.json',
      foregroundAsset: '$weatherOverlayBasePath/drizzle_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Scattered Showers',
    sceneWeather: 'Rainy',
    overlay: WeatherOverlay(
      backgroundAsset:
          '$weatherOverlayBasePath/scattered_showers_background.json',
      foregroundAsset:
          '$weatherOverlayBasePath/scattered_showers_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Storms',
    sceneWeather: 'Rainy',
    overlay: WeatherOverlay(
      backgroundAsset:
          '$weatherOverlayBasePath/strong_storms_v2_background.json',
      foregroundAsset: '$weatherOverlayBasePath/strong_storms_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Rain/Hail',
    sceneWeather: 'Rainy',
    overlay: WeatherOverlay(
      backgroundAsset:
          '$weatherOverlayBasePath/mixed_rain_hail_background.json',
      foregroundAsset:
          '$weatherOverlayBasePath/mixed_rain_hail_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Snowy',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/showers_snow_background.json',
      foregroundAsset: '$weatherOverlayBasePath/showers_snow_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Flurries',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/flurries_background.json',
      foregroundAsset: '$weatherOverlayBasePath/flurries_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Scattered Snow',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/scattered_snow_background.json',
      foregroundAsset: '$weatherOverlayBasePath/scattered_snow_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Heavy Snow',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/heavy_snow_background.json',
      foregroundAsset: '$weatherOverlayBasePath/heavy_snow_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Blowing Snow',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/blowing_snow_background.json',
      foregroundAsset: '$weatherOverlayBasePath/blowing_snow_foreground.json',
    ),
  ),
  WeatherOption(
    label: 'Blizzard',
    sceneWeather: 'Snowy',
    overlay: WeatherOverlay(
      backgroundAsset: '$weatherOverlayBasePath/blizzard_background.json',
      foregroundAsset: '$weatherOverlayBasePath/blizzard_foreground.json',
    ),
  ),
];

WeatherOverlay? overlayForWeather(
  String weather, {
  bool performanceMode = false,
  bool isNight = false,
}) {
  if (performanceMode) {
    return const WeatherOverlay(backgroundAsset: null, foregroundAsset: null);
  }

  final option = _weatherOptionForWeather(weather);
  if (option == null) return null;

  if (isNight) {
    if (weather == 'Clear') {
      return const WeatherOverlay(
        backgroundAsset: '$weatherOverlayBasePath/clear_background_night.json',
        foregroundAsset: null,
      );
    } else if (weather == 'Mostly Sunny') {
      return const WeatherOverlay(
        backgroundAsset: '$weatherOverlayBasePath/mostly_clear_background_night.json',
        foregroundAsset: null,
      );
    } else if (weather == 'Cloudy') {
      return const WeatherOverlay(
        backgroundAsset: '$weatherOverlayBasePath/mostly_cloudy_background_night.json',
        foregroundAsset: null,
      );
    } else if (weather == 'Scattered Showers') {
      return const WeatherOverlay(
        backgroundAsset: '$weatherOverlayBasePath/scattered_showers_background_night.json',
        foregroundAsset: '$weatherOverlayBasePath/scattered_showers_foreground_night.json',
      );
    } else if (weather == 'Scattered Snow') {
      return const WeatherOverlay(
        backgroundAsset: '$weatherOverlayBasePath/scattered_snow_background_night.json',
        foregroundAsset: '$weatherOverlayBasePath/scattered_snow_foreground_night.json',
      );
    }
  }

  return option.overlay;
}

String sceneWeatherForWeather(String weather) {
  return _weatherOptionForWeather(weather)?.sceneWeather ?? weather;
}

WeatherOption? _weatherOptionForWeather(String weather) {
  for (final option in weatherOptions) {
    if (option.label == weather) return option;
  }
  return null;
}
