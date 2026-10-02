import 'package:flutter_test/flutter_test.dart';
import 'package:inclass_act07/pet_game.dart';

void main() {
  test('default name and constructor meters are bounded', () {
    final game = PetGame(happiness: 105, hunger: -5, energy: 120);
    expect(game.name, 'Doggy!');
    expect((game.happiness, game.hunger, game.energy), (100, 0, 100));
    game.dispose();
  });

  for (final hunger in [5, 95]) {
    test('feed at hunger $hunger uses the resulting hunger', () {
      final game = PetGame(hunger: hunger);
      game.feed();
      expect(game.hunger, hunger == 5 ? 0 : 85);
      expect(game.happiness, hunger == 5 ? 30 : 60);
      game.dispose();
    });
  }

  test('play clamps happiness, hunger, and low energy', () {
    final game = PetGame(happiness: 95, hunger: 95, energy: 5);
    game.play();
    expect((game.happiness, game.hunger, game.energy), (100, 100, 0));
    game.play();
    expect((game.happiness, game.hunger, game.energy), (100, 100, 0));
    game.dispose();
  });

  test('rest clamps hunger and recovered energy', () {
    final game = PetGame(hunger: 95, energy: 95);
    game.rest();
    game.rest();
    expect((game.hunger, game.energy), (100, 100));
    game.dispose();
  });

  test('repeated feeding clamps hunger and happiness at zero', () {
    final game = PetGame(hunger: 5, happiness: 10);
    for (var i = 0; i < 10; i++) {
      game.feed();
    }
    expect((game.hunger, game.happiness), (0, 0));
    game.dispose();
  });

  testWidgets('95 to 100 has no penalty; the next tick penalizes', (
    tester,
  ) async {
    final game = PetGame(hunger: 95);
    game.start();
    await tester.pump(const Duration(seconds: 29));
    expect((game.hunger, game.happiness), (95, 50));
    await tester.pump(const Duration(seconds: 1));
    expect((game.hunger, game.happiness), (100, 50));
    await tester.pump(const Duration(seconds: 30));
    expect((game.hunger, game.happiness), (100, 30));
    game.dispose();
  });

  testWidgets('exactly 80 happiness does not qualify for a win', (
    tester,
  ) async {
    final game = PetGame(happiness: 80, hunger: 0);
    game.start();
    await tester.pump(const Duration(minutes: 3));
    expect(game.outcome, PetOutcome.playing);
    game.dispose();
  });

  testWidgets('first crossing above 80 wins after three full minutes', (
    tester,
  ) async {
    final game = PetGame(happiness: 80, hunger: 0);
    game.start();
    game.play();
    await tester.pump(const Duration(minutes: 2, seconds: 59));
    expect(game.outcome, PetOutcome.playing);
    await tester.pump(const Duration(seconds: 1));
    expect(game.outcome, PetOutcome.won);
    final meters = (game.hunger, game.happiness, game.energy);
    game.feed();
    game.play();
    game.rest();
    await tester.pump(const Duration(minutes: 1));
    expect((game.hunger, game.happiness, game.energy), meters);
    game.reset();
    expect(game.outcome, PetOutcome.playing);
    await tester.pump(const Duration(seconds: 30));
    expect(game.hunger, 55);
    game.dispose();
  });

  testWidgets('care above 80 does not restart the continuous win timer', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 0);
    game.start();
    await tester.pump(const Duration(minutes: 2, seconds: 59));
    game.play();
    expect(game.happiness, 100);
    await tester.pump(const Duration(seconds: 1));
    expect(game.outcome, PetOutcome.won);
    game.dispose();
  });

  testWidgets('dropping to 80 at 2:59 cancels; crossing again restarts', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 20);
    game.start();
    await tester.pump(const Duration(minutes: 2, seconds: 59));
    game.feed();
    game.feed();
    expect(game.happiness, 80);
    await tester.pump(const Duration(seconds: 1));
    expect(game.outcome, PetOutcome.playing);
    game.play();
    expect(game.happiness, 90);
    await tester.pump(const Duration(minutes: 2, seconds: 59));
    expect(game.outcome, PetOutcome.playing);
    await tester.pump(const Duration(seconds: 1));
    expect(game.outcome, PetOutcome.won);
    game.dispose();
  });

  testWidgets('loss freezes care and time; reset restarts hunger', (
    tester,
  ) async {
    final game = PetGame(hunger: 95, happiness: 10);
    game.start();
    game.rest();
    expect(game.outcome, PetOutcome.lost);
    final meters = (game.hunger, game.happiness, game.energy);
    game.feed();
    game.play();
    game.rest();
    await tester.pump(const Duration(minutes: 3));
    expect((game.hunger, game.happiness, game.energy), meters);
    game.reset();
    expect((game.hunger, game.happiness, game.energy), (50, 50, 70));
    expect(game.outcome, PetOutcome.playing);
    await tester.pump(const Duration(seconds: 30));
    expect(game.hunger, 55);
    game.dispose();
  });

  testWidgets('timer overflow can trigger a loss', (tester) async {
    final game = PetGame(hunger: 100, happiness: 30);
    game.start();
    await tester.pump(const Duration(seconds: 30));
    expect(game.happiness, 10);
    expect(game.outcome, PetOutcome.lost);
    game.dispose();
  });

  testWidgets('reset cancels the old win and replaces the hunger timer', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 0);
    game.start();
    await tester.pump(const Duration(seconds: 29));
    game.reset();
    game.reset();
    await tester.pump(const Duration(seconds: 1));
    expect(game.hunger, 50);
    await tester.pump(const Duration(seconds: 29));
    expect(game.hunger, 55);
    await tester.pump(const Duration(seconds: 121));
    expect(game.outcome, PetOutcome.playing);
    expect(game.hunger, 75);
    game.dispose();
  });

  testWidgets('dispose cancels timers and prevents later notifications', (
    tester,
  ) async {
    final game = PetGame(happiness: 90, hunger: 0);
    var notifications = 0;
    game.addListener(() => notifications++);
    game.start();
    game.dispose();
    await tester.pump(const Duration(minutes: 4));
    expect(notifications, 0);
    expect((game.hunger, game.happiness), (0, 90));
    expect(tester.takeException(), isNull);
  });
}
