import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare.dart';

class LoopingFlareController extends FlareController {
  final String animationName;
  ActorAnimation? _animation;
  double _time = 0.0;

  // Notifies listeners when the Flare file finishes loading and duration is known.
  final ValueNotifier<double?> durationNotifier = ValueNotifier<double?>(null);

  LoopingFlareController(this.animationName);

  double? get duration => durationNotifier.value;

  @override
  void initialize(FlutterActorArtboard artboard) {
    _animation = artboard.getAnimation(animationName);
    durationNotifier.value = _animation?.duration;
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (_animation == null) return false;

    // Set duration here as a fallback in case initialize() didn't fire the
    // notifier (e.g. the FlareActor reused an existing artboard on navigation).
    if (durationNotifier.value == null) {
      durationNotifier.value = _animation!.duration;
    }

    _time += elapsed;
    _time %= _animation!.duration;
    _animation!.apply(_time, artboard, 1.0);

    return true;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}
}

class FilePair {
  String backgroundFile;
  String animationFile;
  FilePair(this.backgroundFile, this.animationFile);
}


class FroggyAnimation {
  String backgroundFile;
  String animationFile;
  String currentAnimation = '';

  List<String> animationNames = [
    'Hero-Action', 'Sub-Action 01', 'Sub-Action 02'
  ];

  late LoopingFlareController _controller;

  FroggyAnimation({required this.backgroundFile, required this.animationFile}) {
    currentAnimation = animationNames[0];
    _controller = LoopingFlareController(currentAnimation);
  }

  LoopingFlareController get controller => _controller;

  Widget getAnimation() {
    return SizedBox(
      key: ValueKey(animationFile),
      width: double.infinity,
      height: double.infinity,
      child: FlareActor(
        'assets/$animationFile',
        alignment: Alignment.center,
        fit: BoxFit.cover,
        animation: currentAnimation,
        controller: _controller,
        isPaused: false,
      ),
    );
  }

  Widget getBackground() {
    return Image.asset(
      'assets/$backgroundFile',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  void changeAnimation() {
    int index = animationNames.indexOf(currentAnimation);
    index = (index + 1) % animationNames.length;
    currentAnimation = animationNames[index];
    _controller = LoopingFlareController(currentAnimation);
  }
}
