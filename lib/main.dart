import 'package:flutter/material.dart';

import 'pet_game.dart';

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
  const Pet({super.key, this.game});

  final PetGame? game;

  @override
  State<Pet> createState() => _PetState();
}

class _PetState extends State<Pet> {
  late final PetGame _game;
  late final TextEditingController _nameController;

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  void _confirmName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a pet name first.')));
      return;
    }
    _game.rename(name);
    FocusScope.of(context).unfocus();
  }

  String get _moodLabel => switch (_game.mood) {
    PetMood.unhappy => 'Unhappy',
    PetMood.neutral => 'Neutral',
    PetMood.happy => 'Happy',
  };

  Color get _moodColor => switch (_game.mood) {
    PetMood.unhappy => Colors.red,
    PetMood.neutral => Colors.yellow,
    PetMood.happy => Colors.green,
  };

  ({String image, String message}) get _petMood {
    if (_game.outcome == PetOutcome.lost) {
      return (image: 'dog_sleeping.png', message: 'I need a rest.');
    }
    if (_game.outcome == PetOutcome.won) {
      return (image: 'dog_happy.png', message: 'Best day ever!');
    }
    if (_game.hunger > 80) {
      return (image: 'dog_hungry.png', message: "I'm starving!");
    }
    if (_game.mood == PetMood.unhappy) {
      return (image: 'dog_sad.png', message: 'Play with me?');
    }
    if (_game.energy < 20) {
      return (image: 'dog_sleeping.png', message: 'So sleepy...');
    }
    if (_game.happiness > 70) {
      return (image: 'dog_happy.png', message: "I'm so happy!");
    }
    return (image: 'dog_idle.png', message: "Hi, I'm ${_game.name}");
  }

  double get _petScale => _game.happiness > 70
      ? 1.06
      : _game.happiness < 30
      ? 0.94
      : 1.0;

  @override
  void initState() {
    super.initState();
    _game = widget.game ?? PetGame();
    _nameController = TextEditingController(text: _game.name);
    _game.addListener(_onGameChanged);
    _game.start();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    _nameController.dispose();
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
                  Text(
                    _game.name,
                    key: const ValueKey('pet-name'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          maxLength: 30,
                          decoration: const InputDecoration(
                            labelText: 'Pet name',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _confirmName(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _confirmName,
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                      child: ColorFiltered(
                        key: ValueKey(petImage),
                        colorFilter: ColorFilter.mode(
                          _moodColor,
                          BlendMode.modulate,
                        ),
                        child: Image.asset(
                          petImage,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mood: $_moodLabel',
                    key: const ValueKey('mood-label'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_game.isOver) ...[
                    Semantics(
                      liveRegion: true,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                _game.outcome == PetOutcome.won
                                    ? 'You won!'
                                    : 'Game over',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _game.outcome == PetOutcome.won
                                    ? 'Happiness stayed above 80 for 3 minutes.'
                                    : 'Hunger reached 100 and happiness fell to 10 or below.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text('Press Reset to play again.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
                    tween: Tween<double>(begin: 0, end: _game.happiness / 100),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                  const SizedBox(height: 16),
                  _buildMeter('Hunger', _game.hunger),
                  _buildMeter('Energy', _game.energy),
                  _buildMeter('Happiness', _game.happiness),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: _game.isOver ? null : _game.rest,
                        child: const Text('Rest'),
                      ),
                      ElevatedButton(
                        onPressed: _game.isOver ? null : _game.play,
                        child: const Text('Play'),
                      ),
                      ElevatedButton(
                        onPressed: _game.isOver ? null : _game.feed,
                        child: const Text('Feed'),
                      ),
                      ElevatedButton(
                        onPressed: _game.reset,
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
