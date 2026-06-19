import 'package:flutter/foundation.dart';
import '../models/game_models.dart';

enum GameState { welcome, hunting, analyzing, success, failure, celebration }

class GameProvider extends ChangeNotifier {
  GameState _gameState = GameState.welcome;
  int _currentMissionIndex = 0;
  final List<bool> _completedMissions = [false, false, false, false, false];
  int _stars = 0;
  final List<Discovery> _discoveries = [];

  // Cleared on every new capture attempt; set only after analysis completes
  String _lastObjectLabel = '';
  String _lastDetectedColor = '';
  String _lastImagePath = '';

  // ── Getters ──────────────────────────────────────────────
  GameState get gameState => _gameState;
  int get currentMissionIndex => _currentMissionIndex;
  RainbowColor get currentTargetColor =>
      RainbowColor.values[_currentMissionIndex];
  List<bool> get completedMissions => List.unmodifiable(_completedMissions);
  int get stars => _stars;
  List<Discovery> get discoveries => List.unmodifiable(_discoveries);
  String get lastObjectLabel => _lastObjectLabel;
  String get lastDetectedColor => _lastDetectedColor;
  String get lastImagePath => _lastImagePath;
  bool get isGameComplete => _completedMissions.every((c) => c);
  int get completedCount => _completedMissions.where((c) => c).length;

  // ── Actions ───────────────────────────────────────────────

  void startHunt() {
    _gameState = GameState.hunting;
    notifyListeners();
  }

  /// Called the moment the camera returns an image path.
  /// Clears previous results so stale data never leaks into the new analysis.
  void startAnalyzing(String imagePath) {
    _lastImagePath = imagePath;
    _lastObjectLabel = ''; // clear until analysis finishes
    _lastDetectedColor = ''; // clear until analysis finishes
    _gameState = GameState.analyzing;
    debugPrint('[GameProvider] startAnalyzing: $imagePath');
    notifyListeners();
  }

  void onAnalysisSuccess({
    required String objectLabel,
    required String detectedColor,
    required String imagePath,
  }) {
    // Guard: don't double-award if somehow called twice for the same mission
    if (_completedMissions[_currentMissionIndex]) {
      debugPrint('[GameProvider] onAnalysisSuccess: mission $_currentMissionIndex already completed, ignoring');
      return;
    }

    _lastObjectLabel = objectLabel.isNotEmpty ? objectLabel : 'Object';
    _lastDetectedColor = detectedColor.isNotEmpty ? detectedColor : currentTargetColor.displayName;
    _lastImagePath = imagePath;

    debugPrint('[GameProvider] SUCCESS — label:"$_lastObjectLabel"  color:"$_lastDetectedColor"  path:"$_lastImagePath"');

    _completedMissions[_currentMissionIndex] = true;
    _stars += 1;

    _discoveries.add(Discovery(
      imagePath: imagePath,
      objectLabel: _lastObjectLabel,
      detectedColor: _lastDetectedColor,
      targetColor: currentTargetColor,
      discoveredAt: DateTime.now(),
    ));

    _gameState = GameState.success;
    notifyListeners();
  }

  void onAnalysisFailure({
    required String objectLabel,
    required String detectedColor,
    required String imagePath,
  }) {
    _lastObjectLabel = objectLabel.isNotEmpty ? objectLabel : 'Object';
    _lastDetectedColor = detectedColor.isNotEmpty ? detectedColor : 'Unknown';
    _lastImagePath = imagePath;

    debugPrint('[GameProvider] FAILURE — label:"$_lastObjectLabel"  color:"$_lastDetectedColor"  path:"$_lastImagePath"');

    _gameState = GameState.failure;
    notifyListeners();
  }

  /// Advance to the next mission after a success.
  void nextMission() {
    // Safety: only advance if current mission is actually completed
    if (!_completedMissions[_currentMissionIndex]) {
      debugPrint('[GameProvider] nextMission called but mission not completed — ignoring');
      return;
    }

    if (_currentMissionIndex < RainbowColor.values.length - 1) {
      _currentMissionIndex++;
      // Clear last result so the new hunt starts fresh
      _lastObjectLabel = '';
      _lastDetectedColor = '';
      _lastImagePath = '';
      _gameState = GameState.hunting;
      debugPrint('[GameProvider] nextMission → mission $_currentMissionIndex (${currentTargetColor.displayName})');
    } else {
      _gameState = GameState.celebration;
      debugPrint('[GameProvider] nextMission → celebration');
    }
    notifyListeners();
  }

  /// Return to hunt after a failure. Clears all analysis data so the next
  /// capture starts with a completely blank slate.
  void backToHunt() {
    _lastObjectLabel = '';
    _lastDetectedColor = '';
    _lastImagePath = '';
    _gameState = GameState.hunting;
    debugPrint('[GameProvider] backToHunt — state cleared');
    notifyListeners();
  }

  void triggerCelebration() {
    _gameState = GameState.celebration;
    notifyListeners();
  }

  void resetGame() {
    _gameState = GameState.welcome;
    _currentMissionIndex = 0;
    for (int i = 0; i < _completedMissions.length; i++) {
      _completedMissions[i] = false;
    }
    _stars = 0;
    _discoveries.clear();
    _lastObjectLabel = '';
    _lastDetectedColor = '';
    _lastImagePath = '';
    debugPrint('[GameProvider] resetGame');
    notifyListeners();
  }
}
