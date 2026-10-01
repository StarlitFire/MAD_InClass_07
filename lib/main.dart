import 'package:flutter/material.dart';

import 'dart:math' show pi;

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
  int _happiness = 0;
  int _hunger = 0;
  int _energy = 0;
  bool _gameOver = false;
  bool _hasWon = false;

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

  void _updateOutcome() {
    if (_gameOver || _hasWon) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pet Lab')),
      body: Column(),
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
