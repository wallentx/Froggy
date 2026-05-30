import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:lottie/lottie.dart';

import 'animation.dart';
import 'video_exporter.dart';
import 'weather_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google\'s Weather Frog (Froggy)',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const AnimationScreen(),
    );
  }
}

class ParsedScene {
  final int index;
  final String location;
  final String time;
  final String weather;
  ParsedScene({
    required this.index,
    required this.location,
    required this.time,
    required this.weather,
  });
}

const Set<String> _sceneTimeTokens = {'morning', 'day', 'sunset', 'night'};
const Map<String, String> _knownLocationLabels = {
  'fields': 'Fields',
  'hill': 'Hills',
  'mushroom': 'Mushroom',
};

@visibleForTesting
String sceneLocationLabelForBackgroundFile(String backgroundFile) {
  final fileName = backgroundFile.split('/').last;
  final parts = fileName.split('_');
  final timeIndex = parts.indexWhere(_sceneTimeTokens.contains);
  final locationToken = parts.take(timeIndex == -1 ? 1 : timeIndex).join('_');

  return _knownLocationLabels[locationToken] ??
      _titleCaseLocation(locationToken);
}

@visibleForTesting
List<String> locationOptionsForScenes(List<ParsedScene> scenes) {
  final locations = <String>[];
  for (final scene in scenes) {
    if (!locations.contains(scene.location)) {
      locations.add(scene.location);
    }
  }
  return locations;
}

@visibleForTesting
List<String> sceneWeatherOptionsForScenes(List<ParsedScene> scenes) {
  final weather = {for (final scene in scenes) scene.weather};
  const preferredOrder = ['Clear', 'Cloudy', 'Hazy', 'Rainy', 'Snowy'];

  return [
    for (final option in preferredOrder)
      if (weather.remove(option)) option,
    ...weather,
  ];
}

String _titleCaseLocation(String token) {
  return token
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _tvPerformanceFrogFileForBackgroundFile(String backgroundFile) {
  final fileName = backgroundFile.split('/').last;
  final sceneName = fileName.endsWith('_bg.webp')
      ? fileName.substring(0, fileName.length - '_bg.webp'.length)
      : fileName;
  final parts = sceneName.split('_');
  final timeIndex = parts.indexWhere(_sceneTimeTokens.contains);
  if (timeIndex != -1 && timeIndex + 1 < parts.length) {
    parts[timeIndex + 1] = 'sunny';
  }
  return '${parts.join('_')}_frog.flr';
}

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({
    super.key,
    this.forceTvPerformanceMode,
    this.onGreetingRequestForTesting,
    this.onBehaviorChangeRequestForTesting,
  });

  @visibleForTesting
  final bool? forceTvPerformanceMode;

  @visibleForTesting
  final VoidCallback? onGreetingRequestForTesting;

  @visibleForTesting
  final VoidCallback? onBehaviorChangeRequestForTesting;

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

@visibleForTesting
bool shouldUseTvPerformanceMode({
  required bool isAndroid,
  required NavigationMode navigationMode,
  required Size logicalSize,
  required double devicePixelRatio,
}) {
  final physicalWidth = logicalSize.width * devicePixelRatio;
  final physicalHeight = logicalSize.height * devicePixelRatio;
  final isLargeDisplay = physicalWidth >= 1920 && physicalHeight >= 1080;
  final isLandscapeTvShape =
      logicalSize.width > logicalSize.height && logicalSize.shortestSide >= 720;
  final isControllerOrTvDisplay =
      navigationMode == NavigationMode.directional || isLandscapeTvShape;

  return isAndroid && isLargeDisplay && isControllerOrTvDisplay;
}

bool _isSelectKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter;
}

class _AnimationScreenState extends State<AnimationScreen> {
  static const int _tvBackgroundCacheSize = 1280;
  static const int _tvImageCacheEntries = 16;
  static const int _tvImageCacheBytes = 48 * 1024 * 1024;
  static const Duration _defaultFlarePruneDelay = Duration(seconds: 2);
  static const Duration _tvFlarePruneDelay = Duration.zero;
  static const Duration _selectLongPressDuration = Duration(milliseconds: 600);
  static const Duration _selectDoubleClickDuration = Duration(
    milliseconds: 300,
  );
  static const Duration _sceneCrossfadeDuration = Duration(milliseconds: 650);

  final List<FilePair> filePairs = [
    FilePair('fields_day_cloudy_bg.webp', 'fields_day_cloudy_frog.flr'),
    FilePair('fields_day_hazy_bg.webp', 'fields_day_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_day_rainy_frog.flr'),
    FilePair('fields_day_snowy_bg.webp', 'fields_day_snowy_frog.flr'),
    FilePair('fields_day_sunny_bg.webp', 'fields_day_sunny_frog.flr'),
    FilePair('fields_morning_cloudy_bg.webp', 'fields_morning_cloudy_frog.flr'),
    FilePair('fields_morning_hazy_bg.webp', 'fields_morning_hazy_frog.flr'),
    FilePair('fields_morning_rainy_bg.webp', 'fields_morning_rainy_frog.flr'),
    FilePair('fields_morning_snowy_bg.webp', 'fields_morning_snowy_frog.flr'),
    FilePair('fields_morning_sunny_bg.webp', 'fields_morning_sunny_frog.flr'),
    FilePair('fields_night_cloudy_bg.webp', 'fields_night_cloudy_frog.flr'),
    FilePair('fields_night_hazy_bg.webp', 'fields_night_hazy_frog.flr'),
    FilePair('fields_night_rainy_bg.webp', 'fields_night_rainy_frog.flr'),
    FilePair('fields_night_snowy_bg.webp', 'fields_night_snowy_frog.flr'),
    FilePair('fields_night_sunny_bg.webp', 'fields_night_sunny_frog.flr'),
    FilePair('fields_sunset_cloudy_bg.webp', 'fields_sunset_cloudy_frog.flr'),
    FilePair('fields_sunset_hazy_bg.webp', 'fields_sunset_hazy_frog.flr'),
    FilePair('fields_sunset_rainy_bg.webp', 'fields_sunset_rainy_frog.flr'),
    FilePair('fields_sunset_snowy_bg.webp', 'fields_sunset_snowy_frog.flr'),
    FilePair('fields_sunset_sunny_bg.webp', 'fields_sunset_sunny_frog.flr'),
    FilePair('hill_day_cloudy_bg.webp', 'hill_day_cloudy_frog.flr'),
    FilePair('hill_day_hazy_bg.webp', 'hill_day_hazy_frog.flr'),
    FilePair('hill_day_rainy_bg.webp', 'hill_day_rainy_frog.flr'),
    FilePair('hill_day_snowy_bg.webp', 'hill_day_snowy_frog.flr'),
    FilePair('hill_day_sunny_bg.webp', 'hill_day_sunny_frog.flr'),
    FilePair('hill_morning_cloudy_bg.webp', 'hill_morning_cloudy_frog.flr'),
    FilePair('hill_morning_hazy_bg.webp', 'hill_morning_hazy_frog.flr'),
    FilePair('hill_morning_rainy_bg.webp', 'hill_morning_rainy_frog.flr'),
    FilePair('hill_morning_snowy_bg.webp', 'hill_morning_snowy_frog.flr'),
    FilePair('hill_morning_sunny_bg.webp', 'hill_morning_sunny_frog.flr'),
    FilePair('hill_night_cloudy_bg.webp', 'hill_night_cloudy_frog.flr'),
    FilePair('hill_night_hazy_bg.webp', 'hill_night_hazy_frog.flr'),
    FilePair('hill_night_rainy_bg.webp', 'hill_night_rainy_frog.flr'),
    FilePair('hill_night_snowy_bg.webp', 'hill_night_snowy_frog.flr'),
    FilePair('hill_night_sunny_bg.webp', 'hill_night_sunny_frog.flr'),
    FilePair('hill_sunset_cloudy_bg.webp', 'hill_sunset_cloudy_frog.flr'),
    FilePair('hill_sunset_hazy_bg.webp', 'hill_sunset_hazy_frog.flr'),
    FilePair('hill_sunset_rainy_bg.webp', 'hill_sunset_rainy_frog.flr'),
    FilePair('hill_sunset_snowy_bg.webp', 'hill_sunset_snowy_frog.flr'),
    FilePair('hill_sunset_sunny_bg.webp', 'hill_sunset_sunny_frog.flr'),
    FilePair('mushroom_day_cloudy_bg.webp', 'mushroom_day_cloudy_frog.flr'),
    FilePair('mushroom_day_hazy_bg.webp', 'mushroom_day_hazy_frog.flr'),
    FilePair('mushroom_day_rainy_bg.webp', 'mushroom_day_rainy_frog.flr'),
    FilePair('mushroom_day_snowy_bg.webp', 'mushroom_day_snowy_frog.flr'),
    FilePair('mushroom_day_sunny_bg.webp', 'mushroom_day_sunny_frog.flr'),
    FilePair(
      'mushroom_morning_cloudy_bg.webp',
      'mushroom_morning_cloudy_frog.flr',
    ),
    FilePair('mushroom_morning_hazy_bg.webp', 'mushroom_morning_hazy_frog.flr'),
    FilePair(
      'mushroom_morning_rainy_bg.webp',
      'mushroom_morning_rainy_frog.flr',
    ),
    FilePair(
      'mushroom_morning_snowy_bg.webp',
      'mushroom_morning_snowy_frog.flr',
    ),
    FilePair(
      'mushroom_morning_sunny_bg.webp',
      'mushroom_morning_sunny_frog.flr',
    ),
    FilePair('mushroom_night_cloudy_bg.webp', 'mushroom_night_cloudy_frog.flr'),
    FilePair('mushroom_night_hazy_bg.webp', 'mushroom_night_hazy_frog.flr'),
    FilePair('mushroom_night_rainy_bg.webp', 'mushroom_night_rainy_frog.flr'),
    FilePair('mushroom_night_snowy_bg.webp', 'mushroom_night_snowy_frog.flr'),
    FilePair('mushroom_night_sunny_bg.webp', 'mushroom_night_sunny_frog.flr'),
    FilePair(
      'mushroom_sunset_cloudy_bg.webp',
      'mushroom_sunset_cloudy_frog.flr',
    ),
    FilePair('mushroom_sunset_hazy_bg.webp', 'mushroom_sunset_hazy_frog.flr'),
    FilePair('mushroom_sunset_rainy_bg.webp', 'mushroom_sunset_rainy_frog.flr'),
    FilePair('mushroom_sunset_snowy_bg.webp', 'mushroom_sunset_snowy_frog.flr'),
    FilePair('mushroom_sunset_sunny_bg.webp', 'mushroom_sunset_sunny_frog.flr'),
  ];

  int currentIndex = 0;
  late List<FroggyAnimation> froggyAnimations;
  late FroggyAnimation froggyAnimation;

  final GlobalKey _repaintKey = GlobalKey();
  late VideoExporter _exporter;
  late PageController _pageController;

  // Zoom & Pan state
  bool _cameraUnlocked = false;
  final TransformationController _transformationController =
      TransformationController();

  // HUD Visibility state
  bool _showHUD = true;

  // Portrait layout options
  bool _fitWholeScene = false; // Cover vs Contain
  int _cameraFocus = 1; // 0 = Left, 1 = Center, 2 = Right

  // Ambient & Interaction state
  DateTime _lastInteractionTime = DateTime.now();
  Timer? _ambientTimer;
  Timer? _selectLongPressTimer;
  Timer? _selectSingleClickTimer;
  Timer? _sceneResourcePruneTimer;
  bool _isReacting = false;
  bool _selectPressed = false;
  bool _selectLongPressTriggered = false;
  bool _tvSceneMenuOpen = false;
  final FocusNode _mainFocusNode = FocusNode();
  bool _tvPerformanceMode = false;

  // Category Selector Parsed States
  List<ParsedScene> parsedScenes = [];
  String selectedLocation = "Fields";
  String selectedTime = "Day";
  String selectedWeather = "Clear";

  @override
  void initState() {
    super.initState();

    // Enable sticky fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    froggyAnimations = filePairs.map((pair) {
      return FroggyAnimation(
        backgroundFile: pair.backgroundFile,
        animationFile: pair.animationFile,
      );
    }).toList();

    // Parse all file pairs into categorizable scenes
    _parseAllScenes();

    if (Uri.base.queryParameters['index'] != null) {
      currentIndex = int.parse(Uri.base.queryParameters['index']!);
    }

    froggyAnimation = froggyAnimations[currentIndex];
    _syncSelectionsToCurrentIndex(currentIndex);

    _exporter = VideoExporter(_repaintKey);
    _pageController = PageController(initialPage: currentIndex);

    // Dynamic ambient intelligent behavior timer
    _startAmbientTimer();
  }

  @override
  void dispose() {
    // Restore default system UI overlay behavior
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ambientTimer?.cancel();
    _selectLongPressTimer?.cancel();
    _selectSingleClickTimer?.cancel();
    _sceneResourcePruneTimer?.cancel();
    for (final animation in froggyAnimations) {
      animation.dispose();
    }
    _pageController.dispose();
    _transformationController.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  void _parseAllScenes() {
    for (int i = 0; i < filePairs.length; i++) {
      final bg = filePairs[i].backgroundFile;

      final loc = sceneLocationLabelForBackgroundFile(bg);

      String t = "Day";
      if (bg.contains('_morning_')) t = "Morning";
      if (bg.contains('_sunset_')) t = "Sunset";
      if (bg.contains('_night_')) t = "Night";

      // Map 'sunny' to 'Clear' per feedback
      String w = "Clear";
      if (bg.contains('_cloudy_')) w = "Cloudy";
      if (bg.contains('_hazy_')) w = "Hazy";
      if (bg.contains('_rainy_')) w = "Rainy";
      if (bg.contains('_snowy_')) w = "Snowy";

      parsedScenes.add(
        ParsedScene(index: i, location: loc, time: t, weather: w),
      );
    }
  }

  void _syncSelectionsToCurrentIndex(int index) {
    final parsed = parsedScenes[index];
    final canKeepSelectedWeather =
        !_tvPerformanceMode &&
        sceneWeatherForWeather(selectedWeather) == parsed.weather;
    selectedLocation = parsed.location;
    selectedTime = parsed.time;
    selectedWeather = canKeepSelectedWeather ? selectedWeather : parsed.weather;
  }

  void _setCurrentScene(int index) {
    currentIndex = index;
    froggyAnimation =
        froggyAnimations[_animationIndexForScene(
          currentIndex,
          tvPerformanceMode: _tvPerformanceMode,
        )];
    _isReacting = false;
    _syncSelectionsToCurrentIndex(index);
    _recordInteraction();
  }

  int _animationIndexForScene(
    int sceneIndex, {
    required bool tvPerformanceMode,
  }) {
    if (!tvPerformanceMode) return sceneIndex;

    final targetAnimationFile = _tvPerformanceFrogFileForBackgroundFile(
      filePairs[sceneIndex].backgroundFile,
    );
    final targetIndex = filePairs.indexWhere(
      (pair) => pair.animationFile == targetAnimationFile,
    );
    return targetIndex == -1 ? sceneIndex : targetIndex;
  }

  void _showSingleSceneAtIndex(int index) {
    setState(() {
      _setCurrentScene(index);
      _transformationController.value = Matrix4.identity();
    });
    _pruneSceneResourcesAfterTransition();
  }

  void _recordInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  void _pruneSceneResourcesAfterTransition() {
    _sceneResourcePruneTimer?.cancel();
    _sceneResourcePruneTimer = Timer(
      _sceneCrossfadeDuration + const Duration(milliseconds: 100),
      () {
        if (!mounted) return;
        _pruneSceneResources(tvPerformanceMode: true);
      },
    );
  }

  void _handleSelectDown({required bool tvPerformanceMode}) {
    if (_selectPressed) return;

    _selectPressed = true;
    _selectLongPressTriggered = false;
    _selectLongPressTimer?.cancel();
    _selectLongPressTimer = Timer(_selectLongPressDuration, () {
      if (!mounted) return;

      _selectPressed = false;
      _selectLongPressTriggered = true;
      _selectSingleClickTimer?.cancel();
      _selectSingleClickTimer = null;

      if (tvPerformanceMode) {
        _showTvSceneMenu();
      } else {
        _showSceneDrawer();
      }
    });
  }

  void _handleSelectUp() {
    if (!_selectPressed && !_selectLongPressTriggered) return;

    final wasLongPress = _selectLongPressTriggered;
    _selectPressed = false;
    _selectLongPressTriggered = false;
    _selectLongPressTimer?.cancel();

    if (wasLongPress) return;

    final pendingSingleClick = _selectSingleClickTimer;
    if (pendingSingleClick?.isActive ?? false) {
      pendingSingleClick!.cancel();
      _selectSingleClickTimer = null;
      _cycleLoopAnimation();
      return;
    }

    _selectSingleClickTimer = Timer(_selectDoubleClickDuration, () {
      _selectSingleClickTimer = null;
      if (!mounted) return;
      _triggerGreetingReaction();
    });
  }

  void _startAmbientTimer() {
    _ambientTimer?.cancel();
    // Periodically checks if the app is left idle to cycle behaviors
    _ambientTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final idleSeconds = DateTime.now()
          .difference(_lastInteractionTime)
          .inSeconds;
      if (idleSeconds >= 15 && !_isReacting && !_cameraUnlocked) {
        if (idleSeconds % 45 < 15) {
          // Every 45 seconds of idle, play a greeting reaction animation
          _triggerGreetingReaction();
        } else {
          // Every 15 seconds of idle, cycle base behavior loops (excludes Hello/Wave)
          _cycleLoopAnimation();
        }
      }
    });
  }

  void _triggerGreetingReaction() {
    widget.onGreetingRequestForTesting?.call();

    final greetName = froggyAnimation.greetingAnimation;
    if (greetName == null || _isReacting) return;

    final started = froggyAnimation.triggerReaction(
      greetName,
      onComplete: () {
        if (mounted) {
          setState(() {
            _isReacting = false;
          });
        }
      },
    );

    if (started) {
      setState(() {
        _isReacting = true;
      });
    }
  }

  void _nextAnimation() {
    final next = (currentIndex + 1) % froggyAnimations.length;
    if (_tvPerformanceMode) {
      _showSingleSceneAtIndex(next);
      return;
    }

    _recordInteraction();
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousAnimation() {
    final prev =
        (currentIndex - 1 + froggyAnimations.length) % froggyAnimations.length;
    if (_tvPerformanceMode) {
      _showSingleSceneAtIndex(prev);
      return;
    }

    _recordInteraction();
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _cycleLoopAnimation() {
    widget.onBehaviorChangeRequestForTesting?.call();

    final changed = froggyAnimation.changeAnimation();
    if (!changed) return;

    _recordInteraction();
    setState(() {});
  }

  void _cycleWeather(int direction) {
    final weatherChoices = _tvPerformanceMode
        ? sceneWeatherOptionsForScenes(parsedScenes)
        : [for (final option in weatherOptions) option.label];
    final currentWeather = _tvPerformanceMode
        ? sceneWeatherForWeather(selectedWeather)
        : selectedWeather;
    final currentWeatherIndex = weatherChoices.indexOf(currentWeather);
    if (currentWeatherIndex == -1) return;

    final nextWeatherIndex =
        (currentWeatherIndex + direction + weatherChoices.length) %
        weatherChoices.length;

    selectedWeather = weatherChoices[nextWeatherIndex];
    _updateSceneFromSelectors();
  }

  void _updateSceneFromSelectors() {
    _recordInteraction();
    final sceneWeather = sceneWeatherForWeather(selectedWeather);

    // Try to find the exact match index
    int matchIdx = parsedScenes.indexWhere(
      (p) =>
          p.location == selectedLocation &&
          p.time == selectedTime &&
          p.weather == sceneWeather,
    );

    if (matchIdx != -1) {
      if (matchIdx == currentIndex) {
        setState(() {});
      } else if (_tvPerformanceMode) {
        _showSingleSceneAtIndex(matchIdx);
      } else {
        _pageController.jumpToPage(matchIdx);
      }
    } else {
      // Find closest match if combo is not available (e.g. missing bg)
      int closestIdx = parsedScenes.indexWhere(
        (p) => p.location == selectedLocation && p.weather == sceneWeather,
      );

      if (closestIdx == -1) {
        closestIdx = parsedScenes.indexWhere(
          (p) => p.location == selectedLocation && p.time == selectedTime,
        );
      }

      if (closestIdx == -1) {
        closestIdx = parsedScenes.indexWhere(
          (p) => p.location == selectedLocation,
        );
      }

      if (closestIdx != -1) {
        if (_tvPerformanceMode) {
          _showSingleSceneAtIndex(closestIdx);
        } else {
          _pageController.jumpToPage(closestIdx);
          setState(() {
            _syncSelectionsToCurrentIndex(closestIdx);
          });
        }

        // Show standard glassmorphic alert
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Combination not found. Loaded closest: $selectedLocation - $selectedTime ($selectedWeather)',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildSelectionPill({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: activeColor.withValues(alpha: 0.25),
        disabledColor: Colors.transparent,
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: selected ? activeColor : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
        side: BorderSide(
          color: selected ? activeColor.withValues(alpha: 0.5) : Colors.white12,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _showSceneDrawer() {
    _recordInteraction();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      elevation: 10,
      barrierColor: Colors.black45,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final locationOptions = locationOptionsForScenes(parsedScenes);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.86;

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: sheetMaxHeight),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Customize Weather Scene',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Location Row
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: locationOptions.map((loc) {
                                return _buildSelectionPill(
                                  label: loc,
                                  selected: selectedLocation == loc,
                                  activeColor: Colors.cyanAccent,
                                  onTap: () {
                                    setModalState(() => selectedLocation = loc);
                                    _updateSceneFromSelectors();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Time Row
                          const Text(
                            'Time of Day',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Morning', 'Day', 'Sunset', 'Night']
                                  .map((time) {
                                    return _buildSelectionPill(
                                      label: time,
                                      selected: selectedTime == time,
                                      activeColor: Colors.amberAccent,
                                      onTap: () {
                                        setModalState(
                                          () => selectedTime = time,
                                        );
                                        _updateSceneFromSelectors();
                                      },
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Weather Row
                          const Text(
                            'Weather',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            runSpacing: 8,
                            children: weatherOptions.map((option) {
                              final weather = option.label;
                              return _buildSelectionPill(
                                label: weather,
                                selected: selectedWeather == weather,
                                activeColor: Colors.purpleAccent,
                                onTap: () {
                                  setModalState(
                                    () => selectedWeather = weather,
                                  );
                                  _updateSceneFromSelectors();
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTvSceneMenu() {
    if (_tvSceneMenuOpen) return;

    _recordInteraction();
    _tvSceneMenuOpen = true;
    final locationOptions = locationOptionsForScenes(parsedScenes);
    final sceneWeatherOptions = sceneWeatherOptionsForScenes(parsedScenes);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'TV Scene Menu',
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            IconData iconForLocation(String location) {
              if (location == 'Mushroom') return Icons.home_rounded;
              if (location == 'Hills') return Icons.terrain_rounded;
              return Icons.grass_rounded;
            }

            IconData iconForTime(String time) {
              return switch (time) {
                'Morning' => Icons.wb_twilight_rounded,
                'Sunset' => Icons.nights_stay_rounded,
                'Night' => Icons.dark_mode_rounded,
                _ => Icons.wb_sunny_rounded,
              };
            }

            IconData iconForWeather(String weather) {
              return switch (weather) {
                'Cloudy' => Icons.cloud_rounded,
                'Hazy' => Icons.blur_on_rounded,
                'Rainy' => Icons.water_drop_rounded,
                'Snowy' => Icons.ac_unit_rounded,
                _ => Icons.wb_sunny_rounded,
              };
            }

            Widget buildTile({
              required String option,
              required bool selected,
              required Color activeColor,
              required IconData icon,
              required VoidCallback onSelected,
            }) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 22,
                    color: selected ? activeColor : Colors.white60,
                  ),
                  label: Text(option),
                  selected: selected,
                  selectedColor: activeColor.withValues(alpha: 0.24),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  labelStyle: TextStyle(
                    color: selected ? activeColor : Colors.white70,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: BorderSide(
                    color: selected
                        ? activeColor.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.22),
                    width: selected ? 1.5 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (_) => onSelected(),
                ),
              );
            }

            Widget buildSection({
              required String label,
              required IconData icon,
              required List<String> options,
              required String selected,
              required Color activeColor,
              required IconData Function(String option) optionIcon,
              required ValueChanged<String> onSelected,
            }) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          Icon(icon, color: activeColor, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: options.map((option) {
                            return buildTile(
                              option: option,
                              selected: selected == option,
                              activeColor: activeColor,
                              icon: optionIcon(option),
                              onSelected: () {
                                setModalState(() => onSelected(option));
                                _updateSceneFromSelectors();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Material(
              type: MaterialType.transparency,
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.escape ||
                          event.logicalKey == LogicalKeyboardKey.goBack ||
                          event.logicalKey == LogicalKeyboardKey.browserBack)) {
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 54,
                        left: 48,
                        right: 48,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.58),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    blurRadius: 28,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  22,
                                  26,
                                  18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TV Scene Menu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    buildSection(
                                      label: 'Location',
                                      icon: Icons.place_rounded,
                                      options: locationOptions,
                                      selected: selectedLocation,
                                      activeColor: Colors.cyanAccent,
                                      optionIcon: iconForLocation,
                                      onSelected: (value) =>
                                          selectedLocation = value,
                                    ),
                                    buildSection(
                                      label: 'Time',
                                      icon: Icons.schedule_rounded,
                                      options: const [
                                        'Morning',
                                        'Day',
                                        'Sunset',
                                        'Night',
                                      ],
                                      selected: selectedTime,
                                      activeColor: Colors.amberAccent,
                                      optionIcon: iconForTime,
                                      onSelected: (value) =>
                                          selectedTime = value,
                                    ),
                                    buildSection(
                                      label: 'Weather',
                                      icon: Icons.filter_drama_rounded,
                                      options: sceneWeatherOptions,
                                      selected: selectedWeather,
                                      activeColor: Colors.purpleAccent,
                                      optionIcon: iconForWeather,
                                      onSelected: (value) =>
                                          selectedWeather = value,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ).whenComplete(() {
      _tvSceneMenuOpen = false;
    });
  }

  // Check if platform is Android or iOS (mobile / TV device)
  bool get _isMobileDevice {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool _isTvPerformanceMode(BuildContext context) {
    final forced = widget.forceTvPerformanceMode;
    if (forced != null) return forced;
    if (kIsWeb || !Platform.isAndroid) return false;

    final mediaQuery = MediaQuery.of(context);
    return shouldUseTvPerformanceMode(
      isAndroid: true,
      navigationMode: mediaQuery.navigationMode,
      logicalSize: mediaQuery.size,
      devicePixelRatio: mediaQuery.devicePixelRatio,
    );
  }

  void _configureCaches(bool tvPerformanceMode) {
    FlareCache.pruneDelay = tvPerformanceMode
        ? _tvFlarePruneDelay
        : _defaultFlarePruneDelay;

    if (!tvPerformanceMode) return;

    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = _tvImageCacheEntries;
    imageCache.maximumSizeBytes = _tvImageCacheBytes;
  }

  void _pruneSceneResources({required bool tvPerformanceMode}) {
    final retainRadius = tvPerformanceMode ? 0 : 2;
    final retainedAnimationIndexes = tvPerformanceMode
        ? {
            currentIndex,
            _animationIndexForScene(currentIndex, tvPerformanceMode: true),
          }
        : const <int>{};

    for (var i = 0; i < froggyAnimations.length; i++) {
      final shouldRetain = tvPerformanceMode
          ? retainedAnimationIndexes.contains(i)
          : (i - currentIndex).abs() <= retainRadius;
      if (!shouldRetain) {
        final animation = froggyAnimations[i];
        animation.unloadLoadedResources();
        if (tvPerformanceMode) {
          unawaited(AssetImage('assets/${animation.backgroundFile}').evict());
        }
      }
    }

    if (tvPerformanceMode) {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
    }
  }

  Widget _buildWeatherOverlay(
    String asset, {
    required BoxFit fit,
    required Alignment alignment,
  }) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Lottie.asset(
          asset,
          fit: fit,
          alignment: alignment,
          repeat: true,
          animate: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final tvPerformanceMode = _isTvPerformanceMode(context);
    final backgroundCacheSize = tvPerformanceMode
        ? _tvBackgroundCacheSize
        : null;

    _configureCaches(tvPerformanceMode);

    // Immersive custom alignment focusing
    final Alignment cameraAlignment = isPortrait
        ? (_cameraFocus == 0
              ? Alignment.centerLeft
              : (_cameraFocus == 2 ? Alignment.centerRight : Alignment.center))
        : Alignment.center;

    _tvPerformanceMode = tvPerformanceMode;
    froggyAnimation =
        froggyAnimations[_animationIndexForScene(
          currentIndex,
          tvPerformanceMode: tvPerformanceMode,
        )];

    Widget buildScene(int index) {
      final anim = froggyAnimations[index];
      final sceneAnimation =
          froggyAnimations[_animationIndexForScene(
            index,
            tvPerformanceMode: tvPerformanceMode,
          )];
      final overlayWeather = index == currentIndex
          ? selectedWeather
          : parsedScenes[index].weather;
      final overlay = overlayForWeather(
        overlayWeather,
        performanceMode: tvPerformanceMode,
      );

      final Widget sceneContent = Stack(
        children: [
          if (isPortrait && _fitWholeScene) ...[
            BlurredFitBackground(backgroundFile: anim.backgroundFile),
            Center(
              child: AspectRatio(
                aspectRatio: 1.77,
                child: Stack(
                  children: [
                    anim.getBackground(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      cacheWidth: backgroundCacheSize,
                      cacheHeight: backgroundCacheSize,
                    ),
                    if (overlay?.backgroundAsset != null)
                      _buildWeatherOverlay(
                        overlay!.backgroundAsset!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    sceneAnimation.getAnimation(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                    if (overlay?.foregroundAsset != null)
                      _buildWeatherOverlay(
                        overlay!.foregroundAsset!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            anim.getBackground(
              fit: BoxFit.cover,
              alignment: cameraAlignment,
              cacheWidth: backgroundCacheSize,
              cacheHeight: backgroundCacheSize,
            ),
            if (overlay?.backgroundAsset != null)
              _buildWeatherOverlay(
                overlay!.backgroundAsset!,
                fit: BoxFit.cover,
                alignment: cameraAlignment,
              ),
            sceneAnimation.getAnimation(
              fit: BoxFit.cover,
              alignment: cameraAlignment,
            ),
            if (overlay?.foregroundAsset != null)
              _buildWeatherOverlay(
                overlay!.foregroundAsset!,
                fit: BoxFit.cover,
                alignment: cameraAlignment,
              ),
          ],
        ],
      );

      return InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: _cameraUnlocked,
        scaleEnabled: _cameraUnlocked,
        minScale: 1.0,
        maxScale: 4.0,
        onInteractionStart: (_) => _recordInteraction(),
        onInteractionEnd: (details) {
          if (!_cameraUnlocked) {
            _transformationController.value = Matrix4.identity();
          }
        },
        child: sceneContent,
      );
    }

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.keyD) {
            _nextAnimation();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.keyA) {
            _previousAnimation();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.keyS) {
            _cycleWeather(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.keyW) {
            _cycleWeather(-1);
            return KeyEventResult.handled;
          }
          if (_isSelectKey(event.logicalKey)) {
            _handleSelectDown(tvPerformanceMode: tvPerformanceMode);
            return KeyEventResult.handled;
          }
        }
        if (event is KeyUpEvent && _isSelectKey(event.logicalKey)) {
          _handleSelectUp();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          // Root level click toggles HUD visibility
          setState(() {
            _showHUD = !_showHUD;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // RepaintBoundary for video capture, wrapped in scroll listener for desktop mouse zoom
              RepaintBoundary(
                key: _repaintKey,
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent &&
                        _cameraUnlocked) {
                      final double scrollY = pointerSignal.scrollDelta.dy;
                      // Zoom direction: Scroll Up zooms IN, Scroll Down zooms OUT
                      final double zoomDelta = -scrollY / 250.0;
                      final double currentScale = _transformationController
                          .value
                          .getMaxScaleOnAxis();
                      final double newScale = (currentScale + zoomDelta).clamp(
                        1.0,
                        4.0,
                      );

                      if (currentScale != newScale) {
                        final double zoomFactor = newScale / currentScale;
                        final Offset mousePosition =
                            pointerSignal.localPosition;

                        setState(() {
                          _transformationController.value =
                              _transformationController.value.clone()
                                ..translateByDouble(
                                  mousePosition.dx,
                                  mousePosition.dy,
                                  0,
                                  1,
                                )
                                ..scaleByDouble(
                                  zoomFactor,
                                  zoomFactor,
                                  zoomFactor,
                                  1,
                                )
                                ..translateByDouble(
                                  -mousePosition.dx,
                                  -mousePosition.dy,
                                  0,
                                  1,
                                );
                        });
                      }
                    }
                  },
                  child: tvPerformanceMode
                      ? AnimatedSwitcher(
                          duration: _sceneCrossfadeDuration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(
                              filePairs[currentIndex].backgroundFile,
                            ),
                            child: buildScene(currentIndex),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: froggyAnimations.length,
                          physics: _cameraUnlocked
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _setCurrentScene(index);
                            });
                            _pruneSceneResources(
                              tvPerformanceMode: tvPerformanceMode,
                            );
                          },
                          itemBuilder: (context, index) => buildScene(index),
                        ),
                ),
              ),

              // Top Status Bar Indicator (shows up only when camera is unlocked)
              if (_cameraUnlocked)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showHUD,
                    child: AnimatedOpacity(
                      opacity: _showHUD ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isMobileDevice
                                    ? 'Camera Mode: Pinch to Zoom, Drag to Pan'
                                    : 'Camera Mode: Mouse Scroll to Zoom, Drag to Pan',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Desktop Video Export Button (Hidden on Mobile/TV)
              if (!_isMobileDevice)
                Positioned(
                  top: 24,
                  right: 24,
                  child: IgnorePointer(
                    ignoring: !_showHUD,
                    child: AnimatedOpacity(
                      opacity: _showHUD ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Tooltip(
                        message: 'Export as video',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _showExportDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white12,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Premium Glassmorphic Bottom Navigation & Control HUD
              if (!tvPerformanceMode)
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    ignoring: !_showHUD,
                    child: AnimatedOpacity(
                      opacity: _showHUD ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Center(
                        child: GestureDetector(
                          onTap:
                              () {}, // Swallows taps to prevent toggling the HUD when clicking controls
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 12,
                                sigmaY: 12,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Previous Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white70,
                                      ),
                                      onPressed: _previousAnimation,
                                      tooltip: 'Previous Scene',
                                    ),
                                    const SizedBox(width: 4),

                                    // Open 3-Row Segmented Scene Selector Drawer
                                    IconButton(
                                      icon: const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                      ),
                                      onPressed: _showSceneDrawer,
                                      tooltip: 'Weather Scenes',
                                    ),
                                    const SizedBox(width: 4),

                                    ValueListenableBuilder<
                                      AnimationCapabilities
                                    >(
                                      valueListenable:
                                          froggyAnimation.capabilitiesNotifier,
                                      builder: (context, capabilities, _) {
                                        final canTriggerGreeting =
                                            capabilities.canTriggerGreeting;
                                        final canChangeBehavior =
                                            capabilities.canChangeBehavior;
                                        final canPressGreeting =
                                            canTriggerGreeting && !_isReacting;

                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Trigger Waving / Greeting Reactive Animation.
                                            IconButton(
                                              icon: Icon(
                                                _isReacting
                                                    ? Icons.hourglass_empty
                                                    : Icons.front_hand,
                                                color: canTriggerGreeting
                                                    ? (_isReacting
                                                          ? Colors.yellowAccent
                                                          : Colors.tealAccent)
                                                    : Colors.white24,
                                              ),
                                              onPressed: canPressGreeting
                                                  ? () {
                                                      _recordInteraction();
                                                      _triggerGreetingReaction();
                                                    }
                                                  : null,
                                              tooltip: canTriggerGreeting
                                                  ? 'Interact / Say Hello'
                                                  : 'No hello animation',
                                            ),
                                            const SizedBox(width: 4),

                                            // Cycle alternate frog behavior loops.
                                            IconButton(
                                              icon: Icon(
                                                Icons.directions_run,
                                                color: canChangeBehavior
                                                    ? Colors.amberAccent
                                                    : Colors.white24,
                                              ),
                                              onPressed: canChangeBehavior
                                                  ? _cycleLoopAnimation
                                                  : null,
                                              tooltip: canChangeBehavior
                                                  ? 'Change Behavior'
                                                  : 'No alternate behavior',
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        );
                                      },
                                    ),

                                    // Interactive Zoom & Pan Camera Toggle
                                    IconButton(
                                      icon: Icon(
                                        _cameraUnlocked
                                            ? Icons.zoom_in
                                            : Icons.zoom_out,
                                        color: _cameraUnlocked
                                            ? Colors.lightBlueAccent
                                            : Colors.white54,
                                      ),
                                      onPressed: () {
                                        _recordInteraction();
                                        setState(() {
                                          _cameraUnlocked = !_cameraUnlocked;
                                          if (!_cameraUnlocked) {
                                            _transformationController.value =
                                                Matrix4.identity();
                                          }
                                        });
                                      },
                                      tooltip: _cameraUnlocked
                                          ? 'Lock Camera'
                                          : 'Unlock Camera',
                                    ),

                                    // Portrait-specific controls
                                    if (isPortrait) ...[
                                      const SizedBox(width: 4),
                                      // Toggle between Cover (Immersive) and Contain (Fit Scene)
                                      IconButton(
                                        icon: Icon(
                                          _fitWholeScene
                                              ? Icons.fullscreen_exit
                                              : Icons.fullscreen,
                                          color: Colors.greenAccent,
                                        ),
                                        onPressed: () {
                                          _recordInteraction();
                                          setState(() {
                                            _fitWholeScene = !_fitWholeScene;
                                          });
                                        },
                                        tooltip: _fitWholeScene
                                            ? 'Immersive View'
                                            : 'Show Full Scene',
                                      ),
                                      if (!_fitWholeScene) ...[
                                        const SizedBox(width: 4),
                                        // Focus Horizontal Camera cycle (Left, Center, Right)
                                        IconButton(
                                          icon: Icon(
                                            _cameraFocus == 0
                                                ? Icons.align_horizontal_left
                                                : (_cameraFocus == 2
                                                      ? Icons
                                                            .align_horizontal_right
                                                      : Icons
                                                            .align_horizontal_center),
                                            color: Colors.purpleAccent,
                                          ),
                                          onPressed: () {
                                            _recordInteraction();
                                            setState(() {
                                              _cameraFocus =
                                                  (_cameraFocus + 1) % 3;
                                            });
                                          },
                                          tooltip: 'Camera Focus',
                                        ),
                                      ],
                                    ],

                                    const SizedBox(width: 4),
                                    // Next Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white70,
                                      ),
                                      onPressed: _nextAnimation,
                                      tooltip: 'Next Scene',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Full Screen / Desktop Export Dialogue (Kept unchanged for Desktop compatibility)
  Future<void> _showExportDialog() async {
    final ffmpegAvailable = await VideoExporter.isFFmpegAvailable();
    if (!mounted) return;

    final durationNotifier = froggyAnimation.controller.durationNotifier;

    await showDialog<void>(
      context: context,
      builder: (context) => ValueListenableBuilder<double?>(
        valueListenable: durationNotifier,
        builder: (context, loopDuration, _) {
          final durationText = loopDuration != null
              ? '${loopDuration.toStringAsFixed(2)}s (one full loop)'
              : 'Detecting…';

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Export Animation',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!ffmpegAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withAlpha(100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FFmpeg not found. Install FFmpeg and add it to your PATH to export video.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Duration: $durationText',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Exports exactly one seamless loop.\nOutput: ~/Videos/froggy_*.mp4\nRequires FFmpeg in PATH.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Export MP4'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (ffmpegAvailable && loopDuration != null)
                      ? Colors.white
                      : Colors.grey,
                  foregroundColor: Colors.black,
                ),
                onPressed: (ffmpegAvailable && loopDuration != null)
                    ? () {
                        Navigator.pop(context);
                        _startExport(loopDuration, currentIndex);
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startExport(double durationSeconds, int index) async {
    final progressNotifier = ValueNotifier<(double, String)>((
      0.0,
      'Starting…',
    ));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<(double, String)>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          final (progress, status) = value;
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Exporting…',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  status,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep the window visible during capture.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );

    final (outputPath, errorLog) = await _exporter.export(
      durationSeconds: durationSeconds,
      fps: 30,
      index: index,
      onProgress: (progress, status) {
        progressNotifier.value = (progress, status);
      },
    );

    if (mounted) Navigator.of(context).pop();
    progressNotifier.dispose();

    if (!mounted) return;

    if (outputPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $outputPath'),
          backgroundColor: const Color(0xFF2A2A2A),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.white,
            onPressed: () => Process.run('explorer', ['/select,', outputPath]),
          ),
        ),
      );
    } else {
      _showErrorLog(errorLog ?? 'Unknown error.');
    }
  }

  void _showErrorLog(String log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Export failed',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: SizedBox(
          width: 560,
          height: 320,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: SelectableText(
                log,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
