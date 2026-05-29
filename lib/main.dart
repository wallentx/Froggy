import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animation.dart';
import 'video_exporter.dart';

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
      home: AnimationScreen(),
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

class AnimationScreen extends StatefulWidget {
  @override
  _AnimationScreenState createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  final List<FilePair> filePairs = [
    FilePair('fields_day_cloudy_bg.webp', 'fields_day_cloudy_frog.flr'),
    FilePair('fields_day_hazy_bg.webp', 'fields_day_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_day_rainy_frog.flr'),
    FilePair('fields_day_snowy_bg.webp', 'fields_day_snowy_frog.flr'),
    FilePair('fields_day_sunny_bg.webp', 'fields_day_sunny_frog.flr'), 
    FilePair('fields_morning_cloudy_bg.webp', 'fields_morning_cloudy_frog.flr'),
    FilePair('fields_morning_hazy_bg.webp', 'fields_morning_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_morning_rainy_frog.flr'), 
    FilePair('fields_morning_snowy_bg.webp', 'fields_morning_snowy_frog.flr'),
    FilePair('fields_morning_sunny_bg.webp', 'fields_morning_sunny_frog.flr'),
    FilePair('fields_night_hazy_bg.webp', 'fields_night_cloudy_frog.flr'), 
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
    FilePair('hill_day_sunny_bg.webp', 'hill_morning_sunny_frog.flr'), 
    FilePair('hill_night_cloudy_bg.webp', 'hill_night_cloudy_frog.flr'),
    FilePair('hill_night_hazy_bg.webp', 'hill_night_hazy_frog.flr'),
    FilePair('hill_night_rainy_bg.webp', 'hill_night_rainy_frog.flr'),
    FilePair('hill_night_snowy_bg.webp', 'hill_night_snowy_frog.flr'),
    FilePair('hill_night_sunny_bg.webp', 'hill_night_sunny_frog.flr'),
    FilePair('hill_sunset_sunny_bg.webp', 'hill_sunset_sunny_frog.flr'),
    FilePair('mushroom_day_cloudy_bg.webp', 'mushroom_day_cloudy_frog.flr'),
    FilePair('mushroom_day_hazy_bg.webp', 'mushroom_day_hazy_frog.flr'),
    FilePair('mushroom_day_rainy_bg.webp', 'mushroom_day_rainy_frog.flr'),
    FilePair('mushroom_day_snowy_bg.webp', 'mushroom_day_snowy_frog.flr'),
    FilePair('mushroom_day_sunny_bg.webp', 'mushroom_day_sunny_frog.flr'),
    FilePair('mushroom_morning_cloudy_bg.webp', 'mushroom_morning_cloudy_frog.flr'),
    FilePair('mushroom_morning_hazy_bg.webp', 'mushroom_morning_hazy_frog.flr'),
    FilePair('mushroom_morning_rainy_bg.webp', 'mushroom_morning_rainy_frog.flr'),
    FilePair('mushroom_morning_snowy_bg.webp', 'mushroom_morning_snowy_frog.flr'),
    FilePair('mushroom_morning_sunny_bg.webp', 'mushroom_morning_sunny_frog.flr'),
    FilePair('mushroom_night_cloudy_bg.webp', 'mushroom_night_cloudy_frog.flr'),
    FilePair('mushroom_night_hazy_bg.webp', 'mushroom_night_hazy_frog.flr'),
    FilePair('mushroom_night_rainy_bg.webp', 'mushroom_night_rainy_frog.flr'),
    FilePair('mushroom_night_snowy_bg.webp', 'mushroom_night_snowy_frog.flr'),
    FilePair('mushroom_night_sunny_bg.webp', 'mushroom_night_sunny_frog.flr'),
    FilePair('mushroom_sunset_cloudy_bg.webp', 'mushroom_sunset_cloudy_frog.flr'),
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
  final TransformationController _transformationController = TransformationController();

  // HUD Visibility state
  bool _showHUD = true;

  // Portrait layout options
  bool _fitWholeScene = false; // Cover vs Contain
  int _cameraFocus = 1; // 0 = Left, 1 = Center, 2 = Right

  // Ambient & Interaction state
  DateTime _lastInteractionTime = DateTime.now();
  Timer? _ambientTimer;
  bool _isReacting = false;
  final FocusNode _mainFocusNode = FocusNode();

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
          animationFile: pair.animationFile);
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
    _pageController.dispose();
    _transformationController.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  void _parseAllScenes() {
    for (int i = 0; i < filePairs.length; i++) {
      final bg = filePairs[i].backgroundFile;
      
      String loc = "Fields";
      if (bg.startsWith('hill_')) loc = "Hills";
      if (bg.startsWith('mushroom_')) loc = "Mushroom";

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

      parsedScenes.add(ParsedScene(index: i, location: loc, time: t, weather: w));
    }
  }

  void _syncSelectionsToCurrentIndex(int index) {
    final parsed = parsedScenes[index];
    setState(() {
      selectedLocation = parsed.location;
      selectedTime = parsed.time;
      selectedWeather = parsed.weather;
    });
  }

  void _recordInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  void _startAmbientTimer() {
    _ambientTimer?.cancel();
    // Periodically checks if the app is left idle to cycle behaviors
    _ambientTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final idleSeconds = DateTime.now().difference(_lastInteractionTime).inSeconds;
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
    final greetName = froggyAnimation.greetingAnimation;
    if (greetName != null) {
      setState(() {
        _isReacting = true;
      });
      froggyAnimation.triggerReaction(greetName, onComplete: () {
        setState(() {
          _isReacting = false;
        });
      });
    }
  }

  void _nextAnimation() {
    _recordInteraction();
    if (_pageController.hasClients) {
      int next = (currentIndex + 1) % froggyAnimations.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousAnimation() {
    _recordInteraction();
    if (_pageController.hasClients) {
      int prev = (currentIndex - 1 + froggyAnimations.length) % froggyAnimations.length;
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _cycleLoopAnimation() {
    _recordInteraction();
    setState(() {
      froggyAnimation.changeAnimation();
    });
  }

  void _updateSceneFromSelectors() {
    _recordInteraction();
    // Try to find the exact match index
    int matchIdx = parsedScenes.indexWhere((p) =>
        p.location == selectedLocation &&
        p.time == selectedTime &&
        p.weather == selectedWeather);

    if (matchIdx != -1) {
      _pageController.jumpToPage(matchIdx);
    } else {
      // Find closest match if combo is not available (e.g. missing bg)
      int closestIdx = parsedScenes.indexWhere((p) =>
          p.location == selectedLocation && p.weather == selectedWeather);

      if (closestIdx == -1) {
        closestIdx = parsedScenes.indexWhere((p) =>
            p.location == selectedLocation && p.time == selectedTime);
      }

      if (closestIdx == -1) {
        closestIdx = parsedScenes.indexWhere((p) => p.location == selectedLocation);
      }

      if (closestIdx != -1) {
        _pageController.jumpToPage(closestIdx);
        _syncSelectionsToCurrentIndex(closestIdx);

        // Show standard glassmorphic alert
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Combination not found. Loaded closest: ${selectedLocation} - ${selectedTime} (${selectedWeather})',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: Colors.black.withOpacity(0.8),
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
        selectedColor: activeColor.withOpacity(0.25),
        disabledColor: Colors.transparent,
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: selected ? activeColor : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
        side: BorderSide(
          color: selected ? activeColor.withOpacity(0.5) : Colors.white12,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _showSceneDrawer() {
    _recordInteraction();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      elevation: 10,
      barrierColor: Colors.black45,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      style: TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Fields', 'Hills', 'Mushroom'].map((loc) {
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
                      style: TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Morning', 'Day', 'Sunset', 'Night'].map((time) {
                          return _buildSelectionPill(
                            label: time,
                            selected: selectedTime == time,
                            activeColor: Colors.amberAccent,
                            onTap: () {
                              setModalState(() => selectedTime = time);
                              _updateSceneFromSelectors();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weather Row
                    const Text(
                      'Weather',
                      style: TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Clear', 'Cloudy', 'Hazy', 'Rainy', 'Snowy'].map((weather) {
                          return _buildSelectionPill(
                            label: weather,
                            selected: selectedWeather == weather,
                            activeColor: Colors.purpleAccent,
                            onTap: () {
                              setModalState(() => selectedWeather = weather);
                              _updateSceneFromSelectors();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Check if platform is Android or iOS (mobile / TV device)
  bool get _isMobileDevice {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Immersive custom alignment focusing
    final Alignment cameraAlignment = isPortrait
        ? (_cameraFocus == 0
            ? Alignment.centerLeft
            : (_cameraFocus == 2 ? Alignment.centerRight : Alignment.center))
        : Alignment.center;

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
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _cycleLoopAnimation();
            return KeyEventResult.handled;
          }
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
                    if (pointerSignal is PointerScrollEvent && _cameraUnlocked) {
                      final double scrollY = pointerSignal.scrollDelta.dy;
                      // Zoom direction: Scroll Up zooms IN, Scroll Down zooms OUT
                      final double zoomDelta = -scrollY / 250.0;
                      final double currentScale = _transformationController.value.getMaxScaleOnAxis();
                      final double newScale = (currentScale + zoomDelta).clamp(1.0, 4.0);

                      if (currentScale != newScale) {
                        final double zoomFactor = newScale / currentScale;
                        final Offset mousePosition = pointerSignal.localPosition;

                        setState(() {
                          _transformationController.value = _transformationController.value.clone()
                            ..translate(mousePosition.dx, mousePosition.dy)
                            ..scale(zoomFactor)
                            ..translate(-mousePosition.dx, -mousePosition.dy);
                        });
                      }
                    }
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: froggyAnimations.length,
                    physics: _cameraUnlocked
                        ? const NeverScrollableScrollPhysics() // Disable page swiping when panning/zooming
                        : const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                        froggyAnimation = froggyAnimations[currentIndex];
                        _syncSelectionsToCurrentIndex(index);
                        _recordInteraction();
                      });
                    },
                    itemBuilder: (context, index) {
                      final anim = froggyAnimations[index];
                      
                      // Interactive scene rendering with Zoom/Pan capabilities
                      final Widget sceneContent = Stack(
                        children: [
                          // Full contain view with blurred background if fit mode active
                          if (isPortrait && _fitWholeScene) ...[
                            BlurredFitBackground(backgroundFile: anim.backgroundFile),
                            Center(
                              child: AspectRatio(
                                aspectRatio: 1.77, // Fits 16:9 landscape aspect ratio
                                child: Stack(
                                  children: [
                                    anim.getBackground(fit: BoxFit.contain, alignment: Alignment.center),
                                    anim.getAnimation(fit: BoxFit.contain, alignment: Alignment.center),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            anim.getBackground(fit: BoxFit.cover, alignment: cameraAlignment),
                            anim.getAnimation(fit: BoxFit.cover, alignment: cameraAlignment),
                          ],
                        ],
                      );

                      // InteractiveViewer receives all click drags cleanly now, with no gesture tap conflicts!
                      return InteractiveViewer(
                        transformationController: _transformationController,
                        panEnabled: _cameraUnlocked,
                        scaleEnabled: _cameraUnlocked,
                        minScale: 1.0,
                        maxScale: 4.0,
                        onInteractionStart: (_) => _recordInteraction(),
                        onInteractionEnd: (details) {
                          // Resets to normal if locked or user pinches/zooms out completely
                          if (!_cameraUnlocked) {
                            _transformationController.value = Matrix4.identity();
                          }
                        },
                        child: sceneContent,
                      );
                    },
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _isMobileDevice
                                    ? 'Camera Mode: Pinch to Zoom, Drag to Pan'
                                    : 'Camera Mode: Mouse Scroll to Zoom, Drag to Pan',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
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
                                border: Border.all(color: Colors.white12, width: 1),
                              ),
                              child: const Icon(Icons.videocam, color: Colors.white70, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Premium Glassmorphic Bottom Navigation & Control HUD
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
                        onTap: () {}, // Swallows taps to prevent toggling the HUD when clicking controls
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Previous Button
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                                    onPressed: _previousAnimation,
                                    tooltip: 'Previous Scene',
                                  ),
                                  const SizedBox(width: 4),

                                  // Open 3-Row Segmented Scene Selector Drawer
                                  IconButton(
                                    icon: const Icon(Icons.tune, color: Colors.white),
                                    onPressed: _showSceneDrawer,
                                    tooltip: 'Weather Scenes',
                                  ),
                                  const SizedBox(width: 4),

                                  // Trigger Waving / Greeting Reactive Animation (Bespoke)
                                  IconButton(
                                    icon: Icon(
                                      _isReacting ? Icons.hourglass_empty : Icons.front_hand,
                                      color: _isReacting ? Colors.yellowAccent : Colors.tealAccent,
                                    ),
                                    onPressed: _isReacting
                                        ? null
                                        : () {
                                            _recordInteraction();
                                            _triggerGreetingReaction();
                                          },
                                    tooltip: 'Interact / Say Hello',
                                  ),
                                  const SizedBox(width: 4),

                                  // Cycle Base Looping Actions (Excludes Hello/Wave)
                                  IconButton(
                                    icon: const Icon(Icons.directions_run, color: Colors.amberAccent),
                                    onPressed: _cycleLoopAnimation,
                                    tooltip: 'Change Behavior',
                                  ),
                                  const SizedBox(width: 4),

                                  // Interactive Zoom & Pan Camera Toggle
                                  IconButton(
                                    icon: Icon(
                                      _cameraUnlocked ? Icons.zoom_in : Icons.zoom_out,
                                      color: _cameraUnlocked ? Colors.lightBlueAccent : Colors.white54,
                                    ),
                                    onPressed: () {
                                      _recordInteraction();
                                      setState(() {
                                        _cameraUnlocked = !_cameraUnlocked;
                                        if (!_cameraUnlocked) {
                                          _transformationController.value = Matrix4.identity();
                                        }
                                      });
                                    },
                                    tooltip: _cameraUnlocked ? 'Lock Camera' : 'Unlock Camera',
                                  ),

                                  // Portrait-specific controls
                                  if (isPortrait) ...[
                                    const SizedBox(width: 4),
                                    // Toggle between Cover (Immersive) and Contain (Fit Scene)
                                    IconButton(
                                      icon: Icon(
                                        _fitWholeScene ? Icons.fullscreen_exit : Icons.fullscreen,
                                        color: Colors.greenAccent,
                                      ),
                                      onPressed: () {
                                        _recordInteraction();
                                        setState(() {
                                          _fitWholeScene = !_fitWholeScene;
                                        });
                                      },
                                      tooltip: _fitWholeScene ? 'Immersive View' : 'Show Full Scene',
                                    ),
                                    if (!_fitWholeScene) ...[
                                      const SizedBox(width: 4),
                                      // Focus Horizontal Camera cycle (Left, Center, Right)
                                      IconButton(
                                        icon: Icon(
                                          _cameraFocus == 0
                                              ? Icons.align_horizontal_left
                                              : (_cameraFocus == 2
                                                  ? Icons.align_horizontal_right
                                                  : Icons.align_horizontal_center),
                                          color: Colors.purpleAccent,
                                        ),
                                        onPressed: () {
                                          _recordInteraction();
                                          setState(() {
                                            _cameraFocus = (_cameraFocus + 1) % 3;
                                          });
                                        },
                                        tooltip: 'Camera Focus',
                                      ),
                                    ],
                                  ],

                                  const SizedBox(width: 4),
                                  // Next Button
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
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
            title: const Text('Export Animation', style: TextStyle(color: Colors.white)),
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
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
    final progressNotifier =
        ValueNotifier<(double, String)>((0.0, 'Starting…'));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<(double, String)>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          final (progress, status) = value;
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Exporting…', style: TextStyle(color: Colors.white)),
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
                Text(status, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
        title: const Text('Export failed', style: TextStyle(color: Colors.redAccent)),
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
