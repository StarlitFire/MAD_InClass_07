import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act07/main.dart';
import 'package:inclass_act07/pet_game.dart';

Future<void> showPet(
  WidgetTester tester,
  PetGame game, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Pet(game: game),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ElevatedButton button(WidgetTester tester, String label) =>
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label));

void main() {
  for (final boundary in [
    (happiness: 29, label: 'Unhappy', color: Colors.red, scale: 0.94),
    (happiness: 30, label: 'Neutral', color: Colors.yellow, scale: 1.0),
    (happiness: 70, label: 'Neutral', color: Colors.yellow, scale: 1.0),
    (happiness: 71, label: 'Happy', color: Colors.green, scale: 1.06),
  ]) {
    testWidgets('happiness ${boundary.happiness} has matching label and tint', (
      tester,
    ) async {
      await showPet(tester, PetGame(happiness: boundary.happiness));
      expect(find.text('Mood: ${boundary.label}'), findsOneWidget);
      final filter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(
        filter.colorFilter,
        ColorFilter.mode(boundary.color, BlendMode.modulate),
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        boundary.scale,
      );
      final image = tester.widget<Image>(find.byType(Image));
      final path = (image.image as AssetImage).assetName;
      expect(
        path,
        boundary.happiness < 30
            ? 'assets/images/dog/dog_sad.png'
            : boundary.happiness > 70
            ? 'assets/images/dog/dog_happy.png'
            : 'assets/images/dog/dog_idle.png',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('name defaults to Doggy! and is confirmed before updating', (
    tester,
  ) async {
    final game = PetGame();
    await showPet(tester, game);
    expect(find.text('Hi, I\'m Doggy!'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Pip  ');
    expect(game.name, 'Doggy!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(game.name, 'Pip');
    expect(find.text('Hi, I\'m Pip'), findsOneWidget);
    game.reset();
    await tester.pumpAndSettle();
    expect(game.name, 'Pip');
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pump();
    expect(game.name, 'Pip');
    expect(find.text('Enter a pet name first.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('care buttons update meters and expressions immediately', (
    tester,
  ) async {
    final game = PetGame();
    await showPet(tester, game);
    for (var i = 0; i < 3; i++) {
      final play = find.widgetWithText(ElevatedButton, 'Play');
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pumpAndSettle();
    }
    expect((game.happiness, game.hunger, game.energy), (80, 65, 40));
    expect(find.text('Mood: Happy'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/dog/dog_happy.png',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loss is explicit, disables care, and Reset re-enables it', (
    tester,
  ) async {
    final game = PetGame(hunger: 95, happiness: 10);
    await showPet(tester, game);
    game.rest();
    await tester.pumpAndSettle();
    expect(find.text('Game over'), findsOneWidget);
    expect(find.text('Press Reset to play again.'), findsOneWidget);
    for (final label in ['Feed', 'Play', 'Rest']) {
      expect(button(tester, label).onPressed, isNull);
    }
    final reset = find.widgetWithText(ElevatedButton, 'Reset');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('Game over'), findsNothing);
    for (final label in ['Feed', 'Play', 'Rest']) {
      expect(button(tester, label).onPressed, isNotNull);
    }
    await tester.pump(const Duration(seconds: 30));
    expect(game.hunger, 55);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('win feedback appears after three minutes and stops care', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 0);
    await showPet(tester, game);
    await tester.pump(const Duration(minutes: 2, seconds: 59));
    expect(find.text('You won!'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('You won!'), findsOneWidget);
    expect(
      find.text('Happiness stayed above 80 for 3 minutes.'),
      findsOneWidget,
    );
    for (final label in ['Feed', 'Play', 'Rest']) {
      expect(button(tester, label).onPressed, isNull);
    }
    final reset = find.widgetWithText(ElevatedButton, 'Reset');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('You won!'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(game.hunger, 55);
    await tester.pumpWidget(const SizedBox());
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('motion preference $reduceMotion preserves usable feedback', (
      tester,
    ) async {
      final game = PetGame();
      await showPet(tester, game, reduceMotion: reduceMotion);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      );
      for (final switcher in tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      )) {
        expect(switcher.duration == Duration.zero, reduceMotion);
      }
      final meter = tester.widget<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(
        meter.duration,
        reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
      );
      game.play();
      await tester.pumpAndSettle();
      expect(find.text('Mood: Neutral'), findsOneWidget);
      expect(game.happiness, 60);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('layout fits and scrolls at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showPet(tester, PetGame());
      final reset = find.widgetWithText(ElevatedButton, 'Reset');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('leaving the screen disposes timers and name controller', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 0);
    await showPet(tester, game);
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 4));
    expect((game.hunger, game.happiness), (0, 90));
    expect(() => controller.addListener(() {}), throwsFlutterError);
    expect(tester.takeException(), isNull);
  });
}
