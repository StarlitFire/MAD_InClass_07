import 'dart:async';

import 'package:flutter/foundation.dart';

enum PetMood { unhappy, neutral, happy }

enum PetOutcome { playing, won, lost }

/// Owns the care rules and timers. The pet screen owns and disposes this game.
class PetGame extends ChangeNotifier {
  PetGame({
    int happiness = 50,
    int hunger = 50,
    int energy = 70,
    String name = 'Doggy!',
  }) : _happiness = _clamp(happiness),
       _hunger = _clamp(hunger),
       _energy = _clamp(energy),
       _name = name;

  static const hungerInterval = Duration(seconds: 30);
  static const winDuration = Duration(minutes: 3);

  int _happiness;
  int _hunger;
  int _energy;
  String _name;
  PetOutcome _outcome = PetOutcome.playing;
  Timer? _hungerTimer;
  Timer? _winTimer;
  bool _disposed = false;

  int get happiness => _happiness;
  int get hunger => _hunger;
  int get energy => _energy;
  String get name => _name;
  PetOutcome get outcome => _outcome;
  bool get isOver => _outcome != PetOutcome.playing;

  PetMood get mood {
    if (_happiness < 30) return PetMood.unhappy;
    if (_happiness > 70) return PetMood.happy;
    return PetMood.neutral;
  }

  static int _clamp(int value) => value.clamp(0, 100).toInt();

  void start() {
    if (_disposed || isOver) return;
    _startHungerTimer();
    _updateOutcome();
  }

  void feed() {
    if (_disposed || isOver) return;
    _hunger = _clamp(_hunger - 10);
    _happiness = _clamp(_happiness + (_hunger < 30 ? -20 : 10));
    _finishUpdate();
  }

  void play() {
    if (_disposed || isOver) return;
    _hunger = _clamp(_hunger + 5);
    _happiness = _clamp(_happiness + 10);
    _energy = _clamp(_energy - 10);
    _finishUpdate();
  }

  void rest() {
    if (_disposed || isOver) return;
    _hunger = _clamp(_hunger + 5);
    _energy = _clamp(_energy + 10);
    _finishUpdate();
  }

  void rename(String value) {
    final name = value.trim();
    if (_disposed || name.isEmpty || name == _name) return;
    _name = name;
    notifyListeners();
  }

  void reset() {
    if (_disposed) return;
    _stopTimers();
    _happiness = 50;
    _hunger = 50;
    _energy = 70;
    _outcome = PetOutcome.playing;
    _startHungerTimer();
    notifyListeners();
  }

  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(hungerInterval, (_) {
      if (_disposed || isOver) return;
      if (_hunger + 5 > 100) {
        _hunger = 100;
        _happiness = _clamp(_happiness - 20);
      } else {
        _hunger += 5;
      }
      _finishUpdate();
    });
  }

  void _finishUpdate() {
    _updateOutcome();
    notifyListeners();
  }

  void _updateOutcome() {
    if (isOver) return;
    if (_hunger == 100 && _happiness <= 10) {
      _outcome = PetOutcome.lost;
      _stopTimers();
      return;
    }
    if (_happiness <= 80) {
      _winTimer?.cancel();
      _winTimer = null;
      return;
    }
    _winTimer ??= Timer(winDuration, () {
      _winTimer = null;
      if (_disposed || isOver || _happiness <= 80) return;
      _outcome = PetOutcome.won;
      _stopTimers();
      notifyListeners();
    });
  }

  void _stopTimers() {
    _hungerTimer?.cancel();
    _hungerTimer = null;
    _winTimer?.cancel();
    _winTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    super.dispose();
  }
}
