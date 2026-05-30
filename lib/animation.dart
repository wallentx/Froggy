import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare.dart';

class LoopingFlareController extends FlareController {
  String animationName;
  ActorAnimation? _animation;
  double _time = 0.0;

  // Notifies listeners when the Flare file finishes loading and duration is known.
  final ValueNotifier<double?> durationNotifier = ValueNotifier<double?>(null);

  // Expose loaded animations to the UI
  final ValueNotifier<List<String>> availableAnimationsNotifier =
      ValueNotifier<List<String>>([]);

  // One-off reaction animation state
  ActorAnimation? _oneOffAnimation;
  double _oneOffTime = 0.0;
  ui.VoidCallback? _onOneOffComplete;

  // Track environmental background animations (like ants, clouds, leaves) running concurrently
  final List<ActorAnimation> _environmentalAnimations = [];
  final Map<String, double> _envTimes = {};

  // Track the artboard for dynamic one-off requests later
  FlutterActorArtboard? _artboard;

  String? _queuedBaseAnimation;
  ui.VoidCallback? _onQueuedBaseAnimationApplied;
  String? _queuedOneOffAnimationName;
  ui.VoidCallback? _onQueuedOneOffComplete;

  LoopingFlareController(this.animationName);

  double? get duration => durationNotifier.value;
  List<String> get availableAnimations => availableAnimationsNotifier.value;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _artboard = artboard;
    _animation = artboard.getAnimation(animationName);
    durationNotifier.value = _animation?.duration;

    // Dynamically retrieve all animation names in the artboard
    final names = artboard.animations.map((a) => a.name).toList();
    availableAnimationsNotifier.value = names;

    // Parse and register environmental animations:
    // Any animation that does NOT represent a frog action (doesn't contain 'Action')
    // and is not a hello/wave reaction is treated as an environmental layer to run concurrently!
    _environmentalAnimations.clear();
    _envTimes.clear();
    for (final anim in artboard.animations) {
      final name = anim.name;
      final isAction = name.contains('Action');
      final isReaction =
          name.toLowerCase().contains('wave') ||
          name.toLowerCase().contains('hello') ||
          name.toLowerCase().contains('greet');

      if (!isAction && !isReaction) {
        _environmentalAnimations.add(anim);
        _envTimes[name] = 0.0;
      }
    }
  }

  // Changes the base looping animation on-the-fly
  void setBaseAnimation(String name) {
    animationName = name;
    _animation = _artboard?.getAnimation(name);
    durationNotifier.value = _animation?.duration;
    _time = 0.0;
  }

  bool queueBaseAnimation(String name, {ui.VoidCallback? onApplied}) {
    if (_queuedBaseAnimation != null || name == animationName) return false;

    _queuedBaseAnimation = name;
    _onQueuedBaseAnimationApplied = onApplied;
    return true;
  }

  // Requests playing a one-off animation (like a wave/reaction)
  bool playOneOff(String name, {ui.VoidCallback? onComplete}) {
    final artboard = _artboard;
    if (artboard == null) return false;

    final anim = artboard.getAnimation(name);
    if (anim != null) {
      _oneOffAnimation = anim;
      _oneOffTime = 0.0;
      _onOneOffComplete = onComplete;
      return true;
    }
    return false;
  }

  bool queueOneOff(String name, {ui.VoidCallback? onComplete}) {
    final artboard = _artboard;
    if (artboard == null || artboard.getAnimation(name) == null) {
      return false;
    }
    if (_oneOffAnimation != null || _queuedOneOffAnimationName != null) {
      return false;
    }

    _queuedOneOffAnimationName = name;
    _onQueuedOneOffComplete = onComplete;
    return true;
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    // 1. Always advance and apply all environmental animations concurrently in the background
    for (final envAnim in _environmentalAnimations) {
      double t = _envTimes[envAnim.name] ?? 0.0;
      t += elapsed;
      t %= envAnim.duration;
      _envTimes[envAnim.name] = t;
      envAnim.apply(t, artboard, 1.0);
    }

    // 2. Advance and apply the base frog looping behavior
    _animation ??= artboard.getAnimation(animationName);
    if (_animation != null) {
      if (durationNotifier.value == null) {
        durationNotifier.value = _animation!.duration;
      }
      final duration = _animation!.duration;
      final nextTime = _time + elapsed;
      final completedLoop = duration > 0 && nextTime >= duration;
      _time = duration > 0 ? nextTime % duration : 0.0;
      _animation!.apply(_time, artboard, 1.0);

      if (completedLoop) {
        _applyQueuedBaseAnimation();
        _startQueuedOneOff();
      }
    }

    // 3. If a one-off greeting reaction is active, overlay it with mix 1.0
    final oneOff = _oneOffAnimation;
    if (oneOff != null) {
      _oneOffTime += elapsed;
      if (_oneOffTime >= oneOff.duration) {
        oneOff.apply(oneOff.duration, artboard, 1.0);
        _oneOffAnimation = null;
        final callback = _onOneOffComplete;
        _onOneOffComplete = null;
        callback?.call();
      } else {
        oneOff.apply(_oneOffTime, artboard, 1.0);
      }
    }

    return true;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  bool _applyQueuedBaseAnimation() {
    final queuedName = _queuedBaseAnimation;
    if (queuedName == null) return false;

    final onApplied = _onQueuedBaseAnimationApplied;
    _queuedBaseAnimation = null;
    _onQueuedBaseAnimationApplied = null;

    setBaseAnimation(queuedName);
    onApplied?.call();
    return true;
  }

  bool _startQueuedOneOff() {
    final queuedName = _queuedOneOffAnimationName;
    if (queuedName == null) return false;

    final onComplete = _onQueuedOneOffComplete;
    _queuedOneOffAnimationName = null;
    _onQueuedOneOffComplete = null;

    return playOneOff(queuedName, onComplete: onComplete);
  }

  @visibleForTesting
  bool applyQueuedBaseAnimationForTesting() => _applyQueuedBaseAnimation();

  void unloadArtboard() {
    _animation = null;
    _oneOffAnimation = null;
    _onOneOffComplete = null;
    _queuedBaseAnimation = null;
    _onQueuedBaseAnimationApplied = null;
    _queuedOneOffAnimationName = null;
    _onQueuedOneOffComplete = null;
    _environmentalAnimations.clear();
    _envTimes.clear();
    _artboard = null;
    _time = 0.0;
    _oneOffTime = 0.0;
    durationNotifier.value = null;
    availableAnimationsNotifier.value = const [];
  }
}

class FilePair {
  String backgroundFile;
  String animationFile;
  FilePair(this.backgroundFile, this.animationFile);
}

class AnimationCapabilities {
  final String? greetingAnimation;
  final List<String> loopingAnimations;

  const AnimationCapabilities({
    required this.loopingAnimations,
    this.greetingAnimation,
  });

  static const empty = AnimationCapabilities(loopingAnimations: []);

  bool get canTriggerGreeting => greetingAnimation != null;
  bool get canChangeBehavior => loopingAnimations.length > 1;
}

AnimationCapabilities animationCapabilitiesFor(List<String> animationNames) {
  final names = animationNames.where((name) => name.trim().isNotEmpty).toList();
  final greeting = _findGreetingAnimation(names);

  final loopingAnimations = <String>[];
  for (final name in names) {
    final normalized = name.trim();
    if (name == greeting) continue;
    if (normalized == 'Hero-Action' ||
        RegExp(r'^Sub-Action \d+$').hasMatch(normalized)) {
      if (!loopingAnimations.contains(name)) {
        loopingAnimations.add(name);
      }
    }
  }

  return AnimationCapabilities(
    greetingAnimation: greeting,
    loopingAnimations: loopingAnimations,
  );
}

String? _findGreetingAnimation(List<String> names) {
  for (final name in names) {
    final lower = name.toLowerCase();
    if (lower.contains('wave') ||
        lower.contains('hello') ||
        lower.contains('greet')) {
      return name;
    }
  }

  for (final name in names) {
    if (name.trim() == 'Sub-Action 02') {
      return name;
    }
  }

  return null;
}

class FroggyAnimation {
  String backgroundFile;
  String animationFile;
  String currentAnimation = '';

  List<String> loopingAnimations = []; // Excludes the hello/wave action
  String? greetingAnimation; // Bespoke hello reaction
  final ValueNotifier<AnimationCapabilities> capabilitiesNotifier =
      ValueNotifier<AnimationCapabilities>(AnimationCapabilities.empty);

  late LoopingFlareController _controller;
  AnimationCapabilities? _pendingCapabilities;
  bool _capabilitiesNotificationScheduled = false;
  bool _disposed = false;

  FroggyAnimation({required this.backgroundFile, required this.animationFile}) {
    currentAnimation = 'Hero-Action';
    _controller = LoopingFlareController(currentAnimation);

    // Listen for available animations loaded from the artboard
    _controller.availableAnimationsNotifier.addListener(() {
      final allNames = _controller.availableAnimations;
      if (allNames.isNotEmpty) {
        final capabilities = animationCapabilitiesFor(allNames);
        greetingAnimation = capabilities.greetingAnimation;
        loopingAnimations = capabilities.loopingAnimations;
        _publishCapabilitiesLater(capabilities);

        // Keep currentAnimation synced with loop group.
        if (loopingAnimations.isNotEmpty &&
            !loopingAnimations.contains(currentAnimation)) {
          currentAnimation = loopingAnimations[0];
          _controller.setBaseAnimation(currentAnimation);
        }
      }
    });
  }

  LoopingFlareController get controller => _controller;

  void _publishCapabilitiesLater(AnimationCapabilities capabilities) {
    _pendingCapabilities = capabilities;
    if (_capabilitiesNotificationScheduled) return;

    _capabilitiesNotificationScheduled = true;
    Timer.run(() {
      _capabilitiesNotificationScheduled = false;
      final capabilities = _pendingCapabilities;
      _pendingCapabilities = null;
      if (_disposed || capabilities == null) return;

      capabilitiesNotifier.value = capabilities;
    });
  }

  bool get canTriggerGreeting => greetingAnimation != null;
  bool get canChangeBehavior => loopingAnimations.length > 1;

  Widget getAnimation({
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) {
    return SizedBox(
      key: ValueKey(animationFile),
      width: double.infinity,
      height: double.infinity,
      child: FlareActor(
        'assets/$animationFile',
        alignment: alignment,
        fit: fit,
        animation: currentAnimation,
        controller: _controller,
        isPaused: false,
      ),
    );
  }

  Widget getBackground({
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      'assets/$backgroundFile',
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  bool changeAnimation() {
    if (!canChangeBehavior) return false;
    int index = loopingAnimations.indexOf(currentAnimation);
    index = (index + 1) % loopingAnimations.length;
    final nextAnimation = loopingAnimations[index];
    return _controller.queueBaseAnimation(
      nextAnimation,
      onApplied: () => currentAnimation = nextAnimation,
    );
  }

  bool triggerReaction(String name, {ui.VoidCallback? onComplete}) {
    return _controller.queueOneOff(name, onComplete: onComplete);
  }

  void unloadLoadedResources() {
    _pendingCapabilities = null;
    _capabilitiesNotificationScheduled = false;
    greetingAnimation = null;
    loopingAnimations = const [];
    capabilitiesNotifier.value = AnimationCapabilities.empty;
    _controller.unloadArtboard();
  }

  void dispose() {
    _disposed = true;
    _pendingCapabilities = null;
    capabilitiesNotifier.dispose();
    _controller.durationNotifier.dispose();
    _controller.availableAnimationsNotifier.dispose();
  }
}

class BlurredFitBackground extends StatelessWidget {
  final String backgroundFile;

  const BlurredFitBackground({super.key, required this.backgroundFile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scale and blur background to fill empty spaces
        Transform.scale(
          scale: 2.5,
          child: Image.asset(
            'assets/$backgroundFile',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
