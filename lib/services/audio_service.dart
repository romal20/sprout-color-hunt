import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton audio service.
///
/// Audio is skipped entirely on Flutter Web — the audioplayers web backend
/// requires specific server MIME types and AudioContext setup that is fragile
/// in dev environments. All methods fail silently on web so gameplay is
/// never blocked.
///
/// On Android/iOS:
/// - Background music loops at volume 0.12 so TTS remains clearly audible.
/// - Effect sounds (chime, success, celebration) share one player.
///   The previous effect is always stopped before a new one starts.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _bgPlayer;
  AudioPlayer? _fxPlayer;
  bool _bgPlaying = false;

  // ── Background music ──────────────────────────────────────────────────────

  Future<void> playBackground() async {
    if (kIsWeb) return; // web audio skipped — see class doc
    if (_bgPlaying) return;
    try {
      _bgPlayer?.dispose();
      _bgPlayer = AudioPlayer();
      await _bgPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer!.setVolume(0.12);
      await _bgPlayer!.play(AssetSource('audio/background_music.mp3'));
      _bgPlaying = true;
      debugPrint('[AudioService] Background music started');
    } catch (e) {
      debugPrint('[AudioService] playBackground error: $e');
    }
  }

  Future<void> stopBackground() async {
    if (kIsWeb) return;
    try {
      await _bgPlayer?.stop();
      _bgPlayer?.dispose();
      _bgPlayer = null;
      _bgPlaying = false;
      debugPrint('[AudioService] Background music stopped');
    } catch (e) {
      debugPrint('[AudioService] stopBackground error: $e');
    }
  }

  Future<void> restartBackground() async {
    if (kIsWeb) return;
    _bgPlaying = false;
    await playBackground();
  }

  // ── Effect sounds ─────────────────────────────────────────────────────────

  Future<void> _playFx(String asset) async {
    if (kIsWeb) return; // web audio skipped — see class doc
    try {
      await _fxPlayer?.stop();
      _fxPlayer?.dispose();
      _fxPlayer = AudioPlayer();
      await _fxPlayer!.play(AssetSource(asset));
      debugPrint('[AudioService] Playing fx: $asset');
    } catch (e) {
      debugPrint('[AudioService] _playFx error ($asset): $e');
    }
  }

  Future<void> playChime() async => _playFx('audio/chime.mp3');
  Future<void> playSuccess() async => _playFx('audio/success.mp3');

  Future<void> playCelebration() async {
    await stopBackground();
    await _playFx('audio/rainbow_complete.mp3');
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    _bgPlayer?.dispose();
    _fxPlayer?.dispose();
    _bgPlaying = false;
  }
}
