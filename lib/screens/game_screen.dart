import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cube.dart';
import '../models/game_language.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.language});

  final GameLanguage language;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AdService _adService = AdService();
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd(onStateChanged: _onAdStateChanged);
  }

  void _onAdStateChanged(bool ready) {
    if (mounted) setState(() => _adReady = ready);
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  static const List<Color> _edgePalette = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
  ];

  // Ekran genişliğine göre küp boyutu: padding(24) + 6 sütun margin(36) çıkarılıp 6'ya bölünür
  double _cubeSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ((w - 24 - 6.0 * GameProvider.cols) / GameProvider.cols)
        .clamp(36.0, 58.0);
  }

  Border _cubeBorder(int rollTicks) {
    final shift = rollTicks % _edgePalette.length;
    Color colorAt(int i) => _edgePalette[(i + shift) % _edgePalette.length];
    return Border(
      top: BorderSide(color: colorAt(0), width: 2.5),
      right: BorderSide(color: colorAt(1), width: 2.5),
      bottom: BorderSide(color: colorAt(2), width: 2.5),
      left: BorderSide(color: colorAt(3), width: 2.5),
    );
  }

  BoxDecoration _spawnCellDecoration(Cube? cube, int rollTicks) {
    if (cube == null) {
      return BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.black, width: 1.5),
      );
    }
    switch (cube.type) {
      case CubeType.joker:
        return BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade700, width: 2.5),
        );
      case CubeType.hint:
        return BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade400, width: 2.5),
        );
      case CubeType.normal:
        return BoxDecoration(
            color: Colors.white, border: _cubeBorder(rollTicks));
    }
  }

  Color _wordRowCellColor(String state) {
    switch (state) {
      case 'correct':
        return Colors.green.shade300;
      case 'present':
        return Colors.amber.shade400;
      case 'absent':
        return Colors.red.shade300;
      case 'inactive':
        // Hedef kelimeden kısa turlarda kullanılmayan sütun
        return Colors.grey.shade300;
      default:
        return Colors.amber.shade100;
    }
  }

  Color _difficultyColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Future<void> _showStatsDialog(BuildContext ctx, GameProvider provider) async {
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(provider.statsDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow(Icons.emoji_events, provider.labelTotalScore,
                '${provider.score}', Colors.amber.shade700),
            _statRow(Icons.military_tech, provider.labelHighScore,
                '${provider.highScore}', Colors.deepOrange),
            _statRow(Icons.flag, provider.labelRoundsPlayed,
                '${provider.level}', Colors.blue),
            _statRow(Icons.check_circle, provider.labelTargetWords,
                '${provider.targetWordsFound}', Colors.green),
            _statRow(Icons.local_fire_department, provider.labelBestCombo,
                '${provider.bestCombo}', Colors.orange),
            _statRow(Icons.rotate_right, provider.labelTotalRotations,
                '${provider.totalRotationsUsed}', Colors.purple),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(enableFeedback: false),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              provider.resetGame();
            },
            child: Text(provider.newGameLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(enableFeedback: false),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(ctx).pop();
            },
            child: Text(provider.exitLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetGame(
      BuildContext ctx, GameProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(provider.resetConfirmTitle),
        content: Text(provider.resetConfirmMessage),
        actions: [
          TextButton(
            style: TextButton.styleFrom(enableFeedback: false),
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(provider.cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(enableFeedback: false),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(provider.resetLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) provider.resetGame();
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubeSize = _cubeSize(context);

    return ChangeNotifierProvider<GameProvider>(
      create: (_) => GameProvider(language: widget.language),
      child: Builder(
        builder: (context) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _showStatsDialog(context, context.read<GameProvider>());
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Cubeword'),
                actions: [
                  Consumer<GameProvider>(
                    builder: (ctx, provider, _) => IconButton(
                      onPressed: provider.toggleSound,
                      enableFeedback: false,
                      tooltip: provider.isSoundEnabled
                          ? provider.muteSoundTooltip
                          : provider.unmuteSoundTooltip,
                      icon: Icon(
                        provider.isSoundEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                      ),
                    ),
                  ),
                  Consumer<GameProvider>(
                    builder: (ctx, provider, _) => IconButton(
                      onPressed: () => _showStatsDialog(ctx, provider),
                      enableFeedback: false,
                      tooltip: provider.statisticsTooltip,
                      icon: const Icon(Icons.bar_chart),
                    ),
                  ),
                  Consumer<GameProvider>(
                    builder: (ctx, provider, _) => IconButton(
                      onPressed: () => _confirmResetGame(ctx, provider),
                      enableFeedback: false,
                      tooltip: provider.resetGameTooltip,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Consumer<GameProvider>(
                  builder: (context, provider, child) {
                    return DecoratedBox(
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Üst bilgi satırı
                            Row(
                              children: [
                                Text(
                                  '${provider.roundLabel}: ${provider.level}',
                                  key: const Key('score-text'),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _difficultyColor(
                                        provider.difficultyTier),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    provider.difficultyLabel,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                    '${provider.scoreLabel}: ${provider.score}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Combo göstergesi
                            if (provider.comboCount >= 2)
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${provider.comboCount} COMBO  ×${provider.comboMultiplier}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 8),
                            Text(provider.targetWordLabel),
                            const SizedBox(height: 6),
                            // Hedef kelime maskeleri — küp boyutuyla eşleşir
                            Row(
                              children: provider.targetMask.split('').map((ch) {
                                return Container(
                                  width: cubeSize,
                                  height: cubeSize,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    border: Border.all(
                                        color: Colors.black, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    ch.trim().isEmpty ? '' : ch,
                                    style: TextStyle(
                                      fontSize: cubeSize * 0.44,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            // Kalan boşluğu dolduran esnek alan
                            const Spacer(),

                            Text(
                              provider.boardHintText,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black.withValues(alpha: 0.55)),
                            ),
                            const SizedBox(height: 8),
                            _buildRow(context, provider, GameProvider.spawnRow,
                                isWordRow: false, cubeSize: cubeSize),
                            const SizedBox(height: 8),
                            _buildRow(context, provider, GameProvider.wordRow,
                                isWordRow: true, cubeSize: cubeSize),
                            const SizedBox(height: 8),
                            Text(
                                '${provider.wordRowLabel}: ${provider.currentWord}',
                                key: const Key('word-row-text')),
                            const SizedBox(height: 4),
                            Text(
                              provider.statusMessage,
                              key: const Key('status-text'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            // Video reklam butonu — hedef henüz bulunmadıysa göster
                            if (!provider.isTargetRevealed)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.deepOrange
                                        .withValues(alpha: 0.4),
                                    disabledForegroundColor: Colors.white70,
                                    enableFeedback: false,
                                  ),
                                  icon: const Icon(Icons.ondemand_video,
                                      size: 18),
                                  label: Text(
                                    _adReady
                                        ? provider.adWatchLabel(3)
                                        : provider.adLoadingLabel,
                                  ),
                                  onPressed: _adReady
                                      ? () => _adService.showRewardedAd(
                                            onRewarded: () {
                                              if (mounted) {
                                                context
                                                    .read<GameProvider>()
                                                    .addBonusRotations(3);
                                              }
                                            },
                                            onStateChanged: _onAdStateChanged,
                                          )
                                      : null,
                                ),
                              ),
                            const SizedBox(height: 6),
                            // Wrap → küçük ekranlarda düğmeler alt satıra geçer
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  key: const Key('submit-word'),
                                  style: ElevatedButton.styleFrom(
                                      enableFeedback: false),
                                  onPressed: provider.submitWord,
                                  child: Text(provider.submitWordLabel),
                                ),
                                OutlinedButton(
                                  key: const Key('clear-word-row'),
                                  style: OutlinedButton.styleFrom(
                                      enableFeedback: false),
                                  onPressed: provider.clearWordRow,
                                  child: Text(provider.clearRowLabel),
                                ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      enableFeedback: false),
                                  onPressed: provider.isTargetRevealed ||
                                          provider.isRoundStuck
                                      ? provider.nextRound
                                      : null,
                                  child: Text(provider.isRoundStuck
                                      ? provider.skipRoundLabel
                                      : provider.nextRoundLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    GameProvider provider,
    int row, {
    required bool isWordRow,
    required double cubeSize,
  }) {
    return Row(
      children: List.generate(GameProvider.cols, (col) {
        final cube = provider.grid[row][col];
        final rollTicks = provider.rollTickAt(row, col);
        final playable = provider.isPlayableCol(col);
        return Semantics(
          label: _cellSemanticsLabel(provider, col, cube, isWordRow),
          button: true,
          child: GestureDetector(
            key: Key('cell-$row-$col'),
            onTap: !playable
                ? null
                : () {
                    if (isWordRow) {
                      provider.dropCube(col);
                    } else {
                      provider.rotateCube(row, col);
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: cubeSize,
              height: cubeSize,
              margin: const EdgeInsets.only(right: 6),
              decoration: isWordRow
                  ? BoxDecoration(
                      color: _wordRowCellColor(provider.wordRowCellState(col)),
                      border: Border.all(
                        color: !playable
                            ? Colors.grey.shade500
                            : cube == null
                                ? Colors.orange
                                : Colors.black54,
                        width: 1.5,
                      ),
                    )
                  : _spawnCellDecoration(cube, rollTicks),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve:
                          isWordRow ? Curves.easeOutBack : Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: isWordRow
                          ? (child, anim) => ScaleTransition(
                                scale: Tween<double>(begin: 0.4, end: 1.0)
                                    .animate(anim),
                                child:
                                    FadeTransition(opacity: anim, child: child),
                              )
                          : (child, anim) => ScaleTransition(
                                scale: Tween<double>(begin: 0.7, end: 1.0)
                                    .animate(anim),
                                child:
                                    FadeTransition(opacity: anim, child: child),
                              ),
                      child: Text(
                        cube?.currentLetter ??
                            (isWordRow && playable ? '_' : ''),
                        key: ValueKey(
                          isWordRow
                              ? 'w-$col-${cube?.currentLetter ?? "empty"}'
                              : 's-$col-${cube?.currentLetter ?? "empty"}-$rollTicks',
                        ),
                        style: TextStyle(
                            fontSize: cubeSize * 0.44,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  // Özel küp ikonu (sol üst)
                  if (!isWordRow &&
                      cube != null &&
                      cube.type != CubeType.normal)
                    Positioned(
                      left: 1,
                      top: 1,
                      child: Icon(
                        cube.type == CubeType.joker
                            ? Icons.star
                            : Icons.lightbulb,
                        size: cubeSize * 0.22,
                        color: cube.type == CubeType.joker
                            ? Colors.amber.shade700
                            : Colors.blue.shade600,
                      ),
                    ),

                  // Kalan dönüş hakkı (sağ alt)
                  if (!isWordRow && cube != null)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Text(
                        '${cube.rotationLimit}',
                        style: TextStyle(
                          fontSize: cubeSize * 0.18,
                          fontWeight: FontWeight.bold,
                          color: cube.rotationLimit == 0
                              ? Colors.red
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),

                  // Renk körü dostu durum ikonu (sağ üst)
                  if (isWordRow &&
                      cube != null &&
                      provider.wordRowCellState(col) != 'empty')
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Icon(
                        _wordRowStateIcon(provider.wordRowCellState(col)),
                        size: cubeSize * 0.26,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  IconData _wordRowStateIcon(String state) {
    switch (state) {
      case 'correct':
        return Icons.check;
      case 'present':
        return Icons.remove;
      case 'absent':
        return Icons.close;
      default:
        return Icons.circle_outlined;
    }
  }

  String _cellSemanticsLabel(
      GameProvider provider, int col, Cube? cube, bool isWordRow) {
    final isEn = provider.isEnglish;
    if (!provider.isPlayableCol(col)) {
      return isEn
          ? 'Column ${col + 1}, not used this round'
          : 'Sütun ${col + 1}, bu turda kullanılmıyor';
    }
    if (isWordRow) {
      if (cube == null) {
        return isEn
            ? 'Word row, column ${col + 1}, empty'
            : 'Kelime satırı, sütun ${col + 1}, boş';
      }
      final state = provider.wordRowCellState(col);
      final stateLabel = isEn
          ? switch (state) {
              'correct' => 'in the correct spot',
              'present' => 'in the word',
              'absent' => 'not in the word',
              _ => '',
            }
          : switch (state) {
              'correct' => 'doğru yerde',
              'present' => 'kelimede var',
              'absent' => 'kelimede yok',
              _ => '',
            };
      return isEn
          ? 'Word row, column ${col + 1}, letter ${cube.currentLetter}, $stateLabel'
          : 'Kelime satırı, sütun ${col + 1}, harf ${cube.currentLetter}, $stateLabel';
    }
    if (cube == null) {
      return isEn
          ? 'Top row, column ${col + 1}, empty'
          : 'Üst satır, sütun ${col + 1}, boş';
    }
    final typeLabel = isEn
        ? switch (cube.type) {
            CubeType.joker => 'joker cube, ',
            CubeType.hint => 'hint cube, ',
            CubeType.normal => '',
          }
        : switch (cube.type) {
            CubeType.joker => 'joker küp, ',
            CubeType.hint => 'ipucu küpü, ',
            CubeType.normal => '',
          };
    return isEn
        ? '$typeLabel Top row, column ${col + 1}, letter ${cube.currentLetter}, '
            '${cube.rotationLimit} rotations left'
        : '$typeLabel Üst satır, sütun ${col + 1}, harf ${cube.currentLetter}, '
            '${cube.rotationLimit} döndürme hakkı kaldı';
  }
}
