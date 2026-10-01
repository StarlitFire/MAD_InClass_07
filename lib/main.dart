import 'package:flutter/material.dart';

import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Pet(),
    );
  }
}

class Pet extends StatefulWidget {
  const Pet({super.key});

  @override
  State<Pet> createState() => _PetState();
}

class _PetState extends State<Pet> {
  int _happiness = 50;
  int _hunger = 50;
  int _energy = 70;
  bool _gameOver = false;
  bool _hasWon = false;
  Timer? _hungerTimer;
  Timer? _highMoodTimer;
  final String _petName = 'Food';

  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  void _feedPet() {
    if (_gameOver || _hasWon) return;

    final nextHunger = _clampMeter(_hunger - 10);
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
    });
    _updateOutcome();
  }

  void _playPet() {
    if (_gameOver || _hasWon) return;

    final nextHunger = _clampMeter(_hunger + 5);
    final nextHappiness = _clampMeter(_happiness + 10);
    final nextEnergy = _clampMeter(_energy - 10);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
      _energy = nextEnergy;
    });
    _updateOutcome();
  }

  void _restPet() {
    if (_gameOver || _hasWon) return;

    final nextHunger = _clampMeter(_hunger + 5);
    final nextEnergy = _clampMeter(_energy + 10);

    setState(() {
      _hunger = nextHunger;
      _energy = nextEnergy;
    });
    _updateOutcome();
  }

  void _resetPet() {
    setState(() {
      _hunger = 50;
      _energy = 70;
      _happiness = 50;
    });
  }

  void _updateOutcome() {
    if (_gameOver || _hasWon) return;

    if (_hunger == 100 && _happiness <= 10) {
      _highMoodTimer?.cancel();
      _hungerTimer?.cancel();
      setState(() => _gameOver = true);
      return;
    }

    if (_happiness <= 80) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    _highMoodTimer ??= Timer(const Duration(minutes: 3), () {
      _highMoodTimer = null;
      if (!mounted || _gameOver || _happiness <= 80) return;
      setState(() => _hasWon = true);
      _hungerTimer?.cancel();
    });
  }

  ({String image, String message}) get _petMood {
    if (_gameOver) {
      return (image: 'dog_sleeping.png', message: 'I need a rest.');
    }
    if (_hasWon) {
      return (image: 'dog_happy.png', message: 'Best day ever!');
    }
    if (_hunger > 80) {
      return (image: 'dog_hungry.png', message: "I'm starving!");
    }
    if (_happiness <= 30) {
      return (image: 'dog_sad.png', message: 'Play with me?');
    }
    if (_energy < 20) {
      return (image: 'dog_sleeping.png', message: 'So sleepy...');
    }
    if (_happiness > 70) {
      return (image: 'dog_happy.png', message: "I'm so happy!");
    }
    return (image: 'dog_idle.png', message: "Hi, I'm $_petName!");
  }

  double get _petScale => _happiness > 70
      ? 1.06
      : _happiness < 30
      ? 0.94
      : 1.0;

  @override
  void initState() {
    super.initState();
    _hungerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || _gameOver || _hasWon) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_hunger + 5 > 100) {
          _hunger = 100;
          _happiness = _clampMeter(_happiness - 20);
        } else {
          _hunger += 5;
        }
      });
      _updateOutcome();
    });
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    // _nameController.dispose();
    super.dispose();
  }

  Widget _buildMeter(String label, int value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(child: Slider(value: value / 100.0, onChanged: null)),
        SizedBox(
          width: 32,
          child: Text(value.toString(), textAlign: TextAlign.end),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final mood = _petMood;
    final petImage = 'assets/images/dog/${mood.image}';

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Lab'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedScale(
                    scale: _petScale,
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      child: Image.asset(
                        petImage,
                        key: ValueKey(petImage),
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    child: Text(
                      mood.message,
                      key: ValueKey(mood.message),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _happiness / 100),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                  const SizedBox(height: 16),
                  _buildMeter('Hunger', _hunger),
                  _buildMeter('Energy', _energy),
                  _buildMeter('Happiness', _happiness),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: _restPet,
                        child: const Text('Rest'),
                      ),
                      ElevatedButton(
                        onPressed: _playPet,
                        child: const Text('Play'),
                      ),
                      ElevatedButton(
                        onPressed: _feedPet,
                        child: const Text('Feed'),
                      ),
                      ElevatedButton(
                        onPressed: _resetPet,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant PetPainter oldDelegate) {
    return true;
  }
}
