import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SfxKey { rotate, drop, valid, invalid, targetFound, combo }

class SoundService {
  static const String _enabledKey = 'sound_enabled';

  static const Map<SfxKey, String> _assetPaths = {
    SfxKey.rotate: 'sounds/rotate.wav',
    SfxKey.drop: 'sounds/drop.wav',
    SfxKey.valid: 'sounds/valid.wav',
    SfxKey.invalid: 'sounds/invalid.wav',
    SfxKey.targetFound: 'sounds/target_found.wav',
    SfxKey.combo: 'sounds/combo.wav',
  };

  final Map<SfxKey, AudioPlayer> _players = {};
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      // Depolama kullanılamıyorsa varsayılan (açık) kullanılır
    }

    try {
      // Flutter binding'i yoksa (örn. Flutter binding'i olmayan plain test()) ses altyapısını hiç kurma
      ServicesBinding.instance;
    } catch (_) {
      return;
    }

    for (final key in SfxKey.values) {
      try {
        final player = AudioPlayer(playerId: 'sfx_${key.name}');
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        _players[key] = player;
      } catch (_) {
        // Platform desteklemiyorsa (örn. Flutter binding'i olmayan testler) sessizce yok say
      }
    }
  }

  Future<void> play(SfxKey key) async {
    if (!_enabled) return;
    final player = _players[key];
    final path = _assetPaths[key];
    if (player == null || path == null) return;
    try {
      await player.stop();
      await player.play(AssetSource(path));
    } catch (_) {
      // Ses çalınamazsa sessizce yok say
    }
  }

  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    if (!_enabled) {
      // Kapatılınca o an çalmakta olan sesleri de kes
      for (final player in _players.values) {
        player.stop();
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, _enabled);
    } catch (_) {
      // Depolama kullanılamıyorsa yalnızca bellek içi durum değişir
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
