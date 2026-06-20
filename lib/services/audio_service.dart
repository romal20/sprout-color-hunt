import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Singleton audio service.
///
/// Only plays one-shot sound effects — no looping background music.
/// Implements [WidgetsBindingObserver] so all audio stops automatically
/// when the app is paused, goes inactive, is detached, or (on web) the
/// browser tab is hidden or closed.
///
/// Sounds played:
///   chime.mp3           — Start Hunt button, Take Picture button
///   success.mp3         — Correct color detected
///   rainbow_complete.mp3 — All 5 colors found
///
/// All methods fail silently — missing audio files never crash the app.
/// Web audio is skipped entirely (audioplayers web requires specific server
/// MIME-type setup that is unreliable in dev/prod Flutter web builds).
class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    // Register once at construction time so the observer is always active
    WidgetsBinding.instance.addObserver(this);
  }

  /// Single shared player — stop previous before starting next.
  /// Prevents duplicate instances accumulating.
  AudioPlayer? _player;

  // ── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        stopAll();
        break;
      case AppLifecycleState.resumed:
        // Do nothing — no music to restart
        break;
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Stop any currently playing sound and play [asset] once.
  Future<void> _playFx(String asset) async {
    if (kIsWeb) return; // web audio skipped — see class doc
    try {
      // Stop and dispose the old player before creating a new one.
      // This prevents multiple AudioPlayer instances from accumulating.
      await _player?.stop();
      _player?.dispose();
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.release); // play once, no loop
      await _player!.play(AssetSource(asset));
      debugPrint('[AudioService] ▶ $asset');
    } catch (e) {
      debugPrint('[AudioService] _playFx error ($asset): $e');
      // Dispose on error to avoid dangling player
      try {
        _player?.dispose();
      } catch (_) {}
      _player = null;
    }
  }

  /// UI feedback — Start Hunt button, Take Picture button.
  Future<void> playChime() => _playFx('audio/chime.mp3');

  /// Correct color detected.
  Future<void> playSuccess() => _playFx('audio/success.mp3');

  /// All 5 colors found — rainbow complete.
  Future<void> playCelebration() => _playFx('audio/rainbow_complete.mp3');

  /// Stop whatever is currently playing and release the player.
  Future<void> stopAll() async {
    try {
      await _player?.stop();
      _player?.dispose();
      _player = null;
      debugPrint('[AudioService] ■ All audio stopped');
    } catch (e) {
      debugPrint('[AudioService] stopAll error: $e');
    }
  }

  /// Call this only if you need to tear down the service entirely.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    _player = null;
  }
}
