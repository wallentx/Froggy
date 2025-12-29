import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare.dart';

class LoopingFlareController extends FlareController {
  final String animationName;
  late ActorAnimation _animation;
  double _time = 0.0;

  LoopingFlareController(this.animationName);

  @override
  void initialize(FlutterActorArtboard artboard) {
    // Fetch the animation reference from the artboard
    _animation = artboard.getAnimation(animationName)!;
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (_animation == null) return false;

    // Increment time and use modulo for a seamless loop
    _time += elapsed;
    _time %= _animation.duration;

    // Apply the current time to the artboard
    _animation.apply(_time, artboard, 1.0);

    // Return true to keep the animation advancing
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

  FroggyAnimation({required this.backgroundFile, required this.animationFile}) {
    currentAnimation = animationNames[0];
  }

  Widget getAnimation() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FlareActor(
        'assets/$animationFile',
        alignment: Alignment.center,
        fit: BoxFit.cover,
        animation: currentAnimation,
        controller: LoopingFlareController(currentAnimation),
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
  }
}