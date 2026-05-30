import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
