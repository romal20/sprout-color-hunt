import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _bgPlayer;
  AudioPlayer? _fxPlayer;

  Future<void> playSuccess() async {
    try {
      _fxPlayer?.dispose();
      _fxPlayer = AudioPlayer();
      await _fxPlayer!.play(AssetSource('audio/success.mp3'));
    } catch (_) {}
  }

  Future<void> playChime() async {
    try {
      _fxPlayer?.dispose();
      _fxPlayer = AudioPlayer();
      await _fxPlayer!.play(AssetSource('audio/chime.mp3'));
    } catch (_) {}
  }

  Future<void> playCelebration() async {
    try {
      _fxPlayer?.dispose();
      _fxPlayer = AudioPlayer();
      await _fxPlayer!.play(AssetSource('audio/rainbow_complete.mp3'));
    } catch (_) {}
  }

  Future<void> playBackground() async {
    try {
      _bgPlayer?.dispose();
      _bgPlayer = AudioPlayer();
      await _bgPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer!.setVolume(0.3);
      await _bgPlayer!.play(AssetSource('audio/background_music.mp3'));
    } catch (_) {}
  }

  Future<void> stopBackground() async {
    try {
      await _bgPlayer?.stop();
      _bgPlayer?.dispose();
      _bgPlayer = null;
    } catch (_) {}
  }

  void dispose() {
    _bgPlayer?.dispose();
    _fxPlayer?.dispose();
  }
}
