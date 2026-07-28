import 'package:flutter/material.dart';
import '../models/game_language.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isTitleSettled = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _isTitleSettled = true;
        });
      }
    });
  }

  void _startGame(BuildContext context, GameLanguage language) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(language: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF06A),
              Color(0xFF7FE7DC),
              Color(0xFFFF8AA8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: 34,
                left: 28,
                child: _FloatingTile(color: Color(0xFF1F2937), letter: 'K'),
              ),
              const Positioned(
                top: 92,
                right: 30,
                child: _FloatingTile(color: Color(0xFF2563EB), letter: 'O'),
              ),
              const Positioned(
                bottom: 104,
                left: 34,
                child: _FloatingTile(color: Color(0xFFDC2626), letter: 'D'),
              ),
              const Positioned(
                bottom: 46,
                right: 42,
                child: _FloatingTile(color: Color(0xFF16A34A), letter: 'A'),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => _AnimatedTitle(
                        isSettled: _isTitleSettled,
                        maxWidth: constraints.maxWidth,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Küpleri döndür, kelimeyi bul.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontFamilyFallback: [
                          'Montserrat',
                          'Trebuchet MS',
                          'Arial'
                        ],
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 38),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        key: const Key('start-game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          enableFeedback: false,
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontFamilyFallback: [
                              'Montserrat',
                              'Trebuchet MS',
                              'Arial'
                            ],
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _startGame(context, GameLanguage.tr),
                        child: const Text('Başla'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        key: const Key('start-game-en'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF111827),
                          enableFeedback: false,
                          side: const BorderSide(
                              color: Color(0xFF111827), width: 2),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontFamilyFallback: [
                              'Montserrat',
                              'Trebuchet MS',
                              'Arial'
                            ],
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _startGame(context, GameLanguage.en),
                        child: const Text('Start'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Rotate the cubes, find the word.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontFamilyFallback: [
                          'Montserrat',
                          'Trebuchet MS',
                          'Arial'
                        ],
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({required this.isSettled, required this.maxWidth});

  final bool isSettled;
  final double maxWidth;

  static const String _title = 'Cubeword';
  static const double _spacing = 6;
  // Referans oran: 44x50 kutu, 30px yazı (tek satıra sığdırmak için ölçeklenir)
  static const double _refTileWidth = 44;
  static const double _refTileHeight = 50;
  static const double _refFontSize = 30;
  static const List<Color> _colors = [
    Color(0xFF111827),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFFFFB703),
    Color(0xFF7C3AED),
    Color(0xFF0F766E),
    Color(0xFFEA580C),
  ];

  @override
  Widget build(BuildContext context) {
    // Tüm harfler tek satıra sığacak şekilde kutu boyutu ekran genişliğine göre ölçeklenir
    // (yuvarlama hatalarının Wrap'ı ikinci satıra düşürmemesi için 1px pay bırakılır)
    final availableWidth = maxWidth - _spacing * (_title.length - 1) - 1;
    final rawTileWidth = availableWidth / _title.length;
    final tileWidth = rawTileWidth.clamp(24.0, _refTileWidth);
    final scale = tileWidth / _refTileWidth;
    final tileHeight = _refTileHeight * scale;
    final fontSize = _refFontSize * scale;

    return Semantics(
      label: _title,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _spacing,
        runSpacing: _spacing,
        children: List.generate(_title.length, (index) {
          return AnimatedSlide(
            offset: isSettled ? Offset.zero : Offset(0, -4.0 - (index * 0.16)),
            duration: Duration(milliseconds: 560 + (index * 70)),
            curve: Curves.bounceOut,
            child: AnimatedOpacity(
              opacity: isSettled ? 1 : 0,
              duration: Duration(milliseconds: 260 + (index * 45)),
              child: Container(
                width: tileWidth,
                height: tileHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                        color: _colors[index % _colors.length], width: 3),
                    right: BorderSide(
                        color: _colors[(index + 1) % _colors.length], width: 3),
                    bottom: BorderSide(
                        color: _colors[(index + 2) % _colors.length], width: 3),
                    left: BorderSide(
                        color: _colors[(index + 3) % _colors.length], width: 3),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 8),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  _title[index],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontFamilyFallback: const [
                      'Montserrat',
                      'Trebuchet MS',
                      'Arial'
                    ],
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FloatingTile extends StatelessWidget {
  const _FloatingTile({
    required this.color,
    required this.letter,
  });

  final Color color;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.82,
      child: Transform.rotate(
        angle: -0.16,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: color, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                offset: Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            letter,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontFamilyFallback: ['Montserrat', 'Trebuchet MS', 'Arial'],
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
