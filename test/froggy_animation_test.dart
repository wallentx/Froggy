import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_flutter/flare.dart';
import 'package:froggy/animation.dart';

void main() {
  test('hero-only scenes have no greeting or alternate behavior', () {
    final capabilities = animationCapabilitiesFor(['Hero-Action']);

    expect(capabilities.greetingAnimation, isNull);
    expect(capabilities.loopingAnimations, ['Hero-Action']);
    expect(capabilities.canTriggerGreeting, isFalse);
    expect(capabilities.canChangeBehavior, isFalse);
  });

  test(
    'sub action 02 is treated as greeting and excluded from behavior loops',
    () {
      final capabilities = animationCapabilitiesFor([
        'Hero-Action',
        'Sub-Action 01',
        'Sub-Action 02',
        'Sub-Action 03',
      ]);

      expect(capabilities.greetingAnimation, 'Sub-Action 02');
      expect(capabilities.loopingAnimations, [
        'Hero-Action',
        'Sub-Action 01',
        'Sub-Action 03',
      ]);
      expect(capabilities.canTriggerGreeting, isTrue);
      expect(capabilities.canChangeBehavior, isTrue);
    },
  );

  test('explicit greeting names are preferred over sub action fallback', () {
    final capabilities = animationCapabilitiesFor([
      'Hero-Action',
      'Sub-Action 01',
      'Sub-Action 02',
      'Wave',
    ]);

    expect(capabilities.greetingAnimation, 'Wave');
    expect(capabilities.loopingAnimations, [
      'Hero-Action',
      'Sub-Action 01',
      'Sub-Action 02',
    ]);
  });

  testWidgets('capability notifications are deferred after animation loading', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final animation = FroggyAnimation(
      backgroundFile: 'fields_day_cloudy_bg.webp',
      animationFile: 'fields_day_cloudy_frog.flr',
    );
    addTearDown(animation.dispose);

    var notificationCount = 0;
    animation.capabilitiesNotifier.addListener(() {
      notificationCount++;
    });

    animation.controller.availableAnimationsNotifier.value = [
      'Hero-Action',
      'Sub-Action 01',
      'Sub-Action 02',
    ];

    expect(animation.canChangeBehavior, isTrue);
    expect(animation.canTriggerGreeting, isTrue);
    expect(notificationCount, 0);

    await tester.pump(const Duration(milliseconds: 1));

    expect(notificationCount, 1);
  });

  testWidgets('unloading a scene drops loaded animation capabilities', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final animation = FroggyAnimation(
      backgroundFile: 'fields_day_cloudy_bg.webp',
      animationFile: 'fields_day_cloudy_frog.flr',
    );
    addTearDown(animation.dispose);

    animation.controller.availableAnimationsNotifier.value = [
      'Hero-Action',
      'Sub-Action 01',
      'Sub-Action 02',
    ];

    await tester.pump(const Duration(milliseconds: 1));
    expect(animation.canChangeBehavior, isTrue);

    animation.unloadLoadedResources();

    expect(animation.canChangeBehavior, isFalse);
    expect(animation.canTriggerGreeting, isFalse);
    expect(animation.controller.availableAnimations, isEmpty);
    expect(animation.controller.duration, isNull);
  });

  testWidgets('changing behavior waits for the current loop boundary', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final animation = FroggyAnimation(
      backgroundFile: 'fields_day_cloudy_bg.webp',
      animationFile: 'fields_day_cloudy_frog.flr',
    );
    addTearDown(animation.dispose);

    animation.controller.availableAnimationsNotifier.value = [
      'Hero-Action',
      'Sub-Action 01',
    ];

    await tester.pump(const Duration(milliseconds: 1));

    expect(animation.changeAnimation(), isTrue);
    expect(animation.currentAnimation, 'Hero-Action');

    animation.controller.applyQueuedBaseAnimationForTesting();

    expect(animation.currentAnimation, 'Sub-Action 01');
  });

  test('LoopingFlareController pauses after loop completion for Sub-Actions', () {
    final heroAnim = FakeActorAnimation('Hero-Action', 2.0);
    final subAnim = FakeActorAnimation('Sub-Action 01', 3.0);
    final artboard = FakeFlutterActorArtboard([heroAnim, subAnim]);

    // 1. Hero-Action should loop continuously
    final controllerHero = LoopingFlareController('Hero-Action');
    controllerHero.initialize(artboard);
    
    // Advance less than duration
    controllerHero.advance(artboard, 1.5);
    expect(controllerHero.pauseTimeRemaining, 0.0);
    
    // Advance past duration -> loops immediately, no pause
    controllerHero.advance(artboard, 1.0); // total 2.5s (past 2.0s duration)
    expect(controllerHero.pauseTimeRemaining, 0.0);

    // 2. Sub-Action 01 should pause at loop completion
    final controllerSub = LoopingFlareController('Sub-Action 01');
    controllerSub.initialize(artboard);

    // Advance less than duration
    controllerSub.advance(artboard, 2.0);
    expect(controllerSub.pauseTimeRemaining, 0.0);

    // Advance past duration -> triggers pause
    controllerSub.advance(artboard, 1.5); // total 3.5s (past 3.0s duration)
    expect(controllerSub.pauseTimeRemaining, 4.0);

    // During pause, advancing time decreases pauseTimeRemaining
    controllerSub.advance(artboard, 1.0);
    expect(controllerSub.pauseTimeRemaining, 3.0);

    // Once pause completes, it starts looping again
    controllerSub.advance(artboard, 3.5); // completes the 3.0s pause and advances 0.5s into the loop
    expect(controllerSub.pauseTimeRemaining, 0.0);
  });
}

class FakeActorAnimation extends ActorAnimation {
  FakeActorAnimation(String name, double duration) : super(name, 30, duration, true);

  @override
  void apply(double time, ActorArtboard artboard, double mix) {}
}

class FakeFlutterActorArtboard extends FlutterActorArtboard {
  final List<ActorAnimation> _anims;

  FakeFlutterActorArtboard(this._anims) : super(FlutterActor());

  @override
  List<ActorAnimation> get animations => _anims;

  @override
  ActorAnimation? getAnimation(String name) {
    for (final a in _anims) {
      if (a.name == name) return a;
    }
    return null;
  }
}
