import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/color_detection_service.dart';
//import '../services/ml_kit_service.dart';
import '../services/gemini_vision_service.dart';
import '../utils/asset_helper.dart';
import '../widgets/rainbow_progress.dart';
import '../widgets/twinkle_widget.dart';
import '../widgets/discovery_shelf.dart';

// ─────────────────────────────────────────────
// Hunt Screen
// ─────────────────────────────────────────────

class HuntScreen extends StatefulWidget {
  const HuntScreen({super.key});

  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen> with WidgetsBindingObserver {
  bool _showHelp = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speakMission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _speakMission() {
    final provider = context.read<GameProvider>();
    final color = provider.currentTargetColor;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        TtsService().speak(
          'Mission ${color.missionNumber}. ${color.missionInstruction}',
        );
      }
    });
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;
    AudioService().playChime();
    setState(() => _isTakingPicture = true);
    debugPrint('[HuntScreen] _takePicture: starting (kIsWeb=$kIsWeb)');

    // ── Step 1: Camera permission (Android/iOS only — skip on web) ─────────
    if (!kIsWeb) {
      try {
        final status = await Permission.camera.request();
        debugPrint('[HuntScreen] Camera permission status: $status');
        if (!status.isGranted) {
          debugPrint('[HuntScreen] Camera permission denied');
          if (mounted) {
            _showPermissionDenied();
            setState(() => _isTakingPicture = false);
          }
          return;
        }
      } catch (e) {
        debugPrint('[HuntScreen] Permission request error: $e');
        // Non-fatal on some platforms — continue
      }
    }

    // ── Step 2: List cameras ───────────────────────────────────────────────
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
      debugPrint('[HuntScreen] Available cameras: ${cameras.length}');
    } catch (e) {
      debugPrint('[HuntScreen] availableCameras() error: $e');
      if (mounted) {
        _showNoCameraDialog();
        setState(() => _isTakingPicture = false);
      }
      return;
    }

    if (cameras.isEmpty) {
      debugPrint('[HuntScreen] No cameras found');
      if (mounted) {
        _showNoCameraDialog();
        setState(() => _isTakingPicture = false);
      }
      return;
    }

    if (!mounted) return;

    // ── Step 3: Open CameraScreen, get XFile back ──────────────────────────
    XFile? xfile;
    try {
      debugPrint('[HuntScreen] Opening CameraScreen');
      xfile = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(camera: cameras.first),
        ),
      );
      debugPrint('[HuntScreen] CameraScreen returned: ${xfile?.path}');
    } catch (e) {
      debugPrint('[HuntScreen] CameraScreen navigation error: $e');
      if (mounted) {
        _showErrorDialog('Could not open camera. Please try again!');
        setState(() => _isTakingPicture = false);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isTakingPicture = false);

    if (xfile == null) {
      debugPrint('[HuntScreen] User cancelled capture');
      return; // user pressed back — silent, no error
    }

    // ── Step 4: On web use bytes; on native verify file exists ─────────────
    if (kIsWeb) {
      debugPrint('[HuntScreen] Web: reading XFile bytes');
      try {
        final bytes = await xfile
            .readAsBytes()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('readAsBytes timed out');
        });
        debugPrint(
            '[HuntScreen] Web: got ${bytes.length} bytes, path=${xfile.path}');
        // analysis is async — don't await, navigation happens inside it
        _analyzeImageWeb(bytes, xfile.path);
      } catch (e) {
        debugPrint('[HuntScreen] Web: readAsBytes error: $e');
        if (mounted)
          _showErrorDialog('Could not read the picture. Please try again!');
      }
    } else {
      // Native: verify file on disk before analysis
      try {
        final file = File(xfile.path);
        final exists = file.existsSync();
        debugPrint('[HuntScreen] Native: exists=$exists path=${xfile.path}');
        if (exists) {
          _analyzeImageNative(xfile.path);
        } else {
          debugPrint('[HuntScreen] Native: file NOT found after capture');
          if (mounted)
            _showErrorDialog('Could not save the picture. Please try again!');
        }
      } catch (e) {
        debugPrint('[HuntScreen] Native file check error: $e');
        if (mounted)
          _showErrorDialog('Could not read the picture. Please try again!');
      }
    }
  }

  // ── Web analysis path (uses bytes, skips ML Kit) ──────────────────────────
  Future<void> _analyzeImageWeb(Uint8List bytes, String imagePath) async {
    debugPrint('[HuntScreen] _analyzeImageWeb: ${bytes.length} bytes');
    final provider = context.read<GameProvider>();
    provider.startAnalyzing(imagePath);

    // ── Color detection with 5s timeout ───────────────────────────────────
    ColorDetectionResult colorResult;
    try {
      colorResult = await Future(
        () => ColorDetectionService.detectDominantColorFromBytes(bytes),
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('[HuntScreen] Web color detection timed out');
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      });
      debugPrint('[HuntScreen] Web color result: ${colorResult.colorName}');
    } catch (e) {
      debugPrint('[HuntScreen] Web color detection error: $e');
      colorResult = ColorDetectionResult(
          colorName: 'Red', rainbowColor: RainbowColor.red);
    }

    // ML Kit not available on web — use 'Object'
    //const label = 'Object';
    String label;

    try {
      label = await GeminiVisionService().analyzeImage(imagePath);
    } catch (e) {
      label = 'Object';
    }

    if (!mounted) return;

    final targetColor = provider.currentTargetColor;
    final isMatch = colorResult.rainbowColor == targetColor;
    final colorName = colorResult.colorName.isNotEmpty
        ? colorResult.colorName
        : targetColor.displayName;

    final objectLabel = label.isNotEmpty ? label : 'Object';

    debugPrint('==========================');
    debugPrint('TARGET: ${targetColor.displayName}');
    debugPrint('DETECTED COLOR: $colorName');
    debugPrint('OBJECT: $objectLabel');
    debugPrint('MATCH: $isMatch');
    debugPrint('CURRENT STATE: ${provider.gameState}');
    debugPrint('==========================');

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      debugPrint('========== RESULT ==========');
      debugPrint('Target Color : ${targetColor.displayName}');
      debugPrint('Detected     : $colorName');
      debugPrint('Object       : $objectLabel');
      debugPrint('Match        : $isMatch');
      debugPrint('============================');

      if (isMatch) {
        debugPrint('CALLING SUCCESS');

        provider.onAnalysisSuccess(
          objectLabel: objectLabel,
          detectedColor: colorName,
          imagePath: imagePath,
        );

        debugPrint('SUCCESS CALLED');
      } else {
        debugPrint('CALLING FAILURE');

        provider.onAnalysisFailure(
          objectLabel: objectLabel,
          detectedColor: colorName,
          imagePath: imagePath,
        );

        debugPrint('FAILURE CALLED');
      }
    });
  }

  // ── Native analysis path (uses file path, runs ML Kit) ────────────────────
  Future<void> _analyzeImageNative(String imagePath) async {
    debugPrint('[HuntScreen] _analyzeImageNative: $imagePath');
    final provider = context.read<GameProvider>();
    provider.startAnalyzing(imagePath);

    // ── Color detection with 5s timeout ───────────────────────────────────
    ColorDetectionResult colorResult;
    try {
      colorResult = await Future(
        () => ColorDetectionService.detectDominantColor(imagePath),
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('[HuntScreen] Native color detection timed out');
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      });
      debugPrint('[HuntScreen] Native color result: ${colorResult.colorName}');
    } catch (e) {
      debugPrint('[HuntScreen] Native color detection error: $e');
      colorResult = ColorDetectionResult(
          colorName: 'Red', rainbowColor: RainbowColor.red);
    }

    // ── ML Kit labeling with 5s timeout (already inside MlKitService) ─────
    // String label;
    // try {
    //   label = await MlKitService()
    //       .labelImage(imagePath)
    //       .timeout(const Duration(seconds: 5), onTimeout: () {
    //     debugPrint('[HuntScreen] ML Kit outer timeout');
    //     return 'Object';
    //   });
    //   debugPrint('[HuntScreen] ML Kit label: $label');
    // } catch (e) {
    //   debugPrint('[HuntScreen] ML Kit error: $e');
    //   label = 'Object';
    // }
    String label;
    try {
      label = await GeminiVisionService()
          .analyzeImage(imagePath)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        debugPrint('[HuntScreen] Gemini timeout');
        return 'Object';
      });

      debugPrint('[HuntScreen] Gemini label: $label');
    } catch (e) {
      debugPrint('[HuntScreen] Gemini error: $e');
      label = 'Object';
    }

    try {
      debugPrint('STEP A');

      final targetColor = provider.currentTargetColor;

      debugPrint('STEP B');

      final isMatch = colorResult.rainbowColor == targetColor;

      debugPrint('STEP C');

      final colorName = colorResult.colorName.isNotEmpty
          ? colorResult.colorName
          : targetColor.displayName;

      debugPrint('STEP D');

      final objectLabel = label.isNotEmpty ? label : 'Object';

      debugPrint('STEP E');

      debugPrint(
          '[HuntScreen] Native — target:${targetColor.displayName} detected:$colorName match:$isMatch label:$objectLabel');

      if (isMatch) {
        debugPrint('STEP SUCCESS');

        provider.onAnalysisSuccess(
          objectLabel: objectLabel,
          detectedColor: colorName,
          imagePath: imagePath,
        );
      } else {
        debugPrint('STEP FAILURE');

        provider.onAnalysisFailure(
          objectLabel: objectLabel,
          detectedColor: colorName,
          imagePath: imagePath,
        );
      }
    } catch (e, st) {
      debugPrint('CRASH FOUND');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  void _showPermissionDenied() {
    showDialog(
      context: context,
      builder: (_) => _ChildDialog(
        emoji: '🙈',
        title: 'Oops!',
        message: 'We need your camera to play!\nAsk a grown-up to help.',
        buttonText: 'OK!',
        onButton: () => Navigator.pop(context),
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (_) => _ChildDialog(
        emoji: '📷',
        title: 'No Camera!',
        message: 'No camera found on this device.',
        buttonText: 'OK!',
        onButton: () => Navigator.pop(context),
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => _ChildDialog(
        emoji: '😅',
        title: 'Oops!',
        message: msg,
        buttonText: 'Try Again!',
        onButton: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final color = provider.currentTargetColor;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF70CAFF),
              Color(0xFFB8E8FF),
              Color(0xFFDFF5FF),
              Color(0xFFC8F0B0),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildTopBar(provider, color),
                        const SizedBox(height: 6),
                        _buildMissionCard(color),
                        const SizedBox(height: 8),
                        _buildTwinkleAndHelp(color),
                        const SizedBox(height: 10),
                        _buildCameraButton(),
                        const SizedBox(height: 12),
                        DiscoveryShelf(discoveries: provider.discoveries),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(GameProvider provider, RainbowColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          AssetHelper.safeImage(
            'assets/images/twinkle.png',
            width: 42,
            height: 42,
            fallback: const TwinkleStarWidget(size: 42),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RainbowProgressWidget(
              completedMissions: provider.completedMissions,
              currentMission: provider.currentMissionIndex,
            ),
          ),
          const SizedBox(width: 8),
          _StarBadge(stars: provider.stars),
        ],
      ),
    );
  }

  Widget _buildMissionCard(RainbowColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: color.color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSION ${color.missionNumber}',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999AB8),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      color.missionTitle,
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color.darkColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    color.missionInstruction,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      color: const Color(0xFF6A6A8A),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Color circle
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.color,
                boxShadow: [
                  BoxShadow(
                    color: color.color.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwinkleAndHelp(RainbowColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TwinkleWidget(size: 68),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHelp = !_showHelp),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showHelp
                    ? _HelpCard(key: const ValueKey('help'), color: color)
                    : _HelpTeaser(key: const ValueKey('teaser'), color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isTakingPicture ? null : _takePicture,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isTakingPicture
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : [
                        const Color(0xFF9B6DFF),
                        const Color(0xFF6C4DFF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C4DFF).withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isTakingPicture
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  )
                : const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 42),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Take Picture',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4455AA),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Star badge
// ─────────────────────────────────────────────
class _StarBadge extends StatelessWidget {
  final int stars;
  const _StarBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD84D),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD84D).withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFF8B6914), size: 18),
          const SizedBox(width: 3),
          Text(
            '$stars',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A4000),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Help widgets
// ─────────────────────────────────────────────
class _HelpTeaser extends StatelessWidget {
  final RainbowColor color;
  const _HelpTeaser({super.key, required this.color});

  static const Map<String, String> _emojiMap = {
    'Apple': '🍎',
    'Book': '📚',
    'Balloon': '🎈',
    'Shirt': '👕',
    'Bottle': '🍶',
    'Cap': '🧢',
    'Pillow': '🛋️',
    'Leaf': '🍃',
    'Toy': '🧸',
    'Notebook': '📓',
    'Vegetable': '🥦',
    'Banana': '🍌',
    'Ball': '⚽',
    'Star': '⭐',
    'Crayon': '🖍️',
    'Bag': '👜',
    'Cloth': '🧣',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any object with this color is okay!',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.darkColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: color.examples
                .take(4)
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _emojiMap[e] ?? '🎨',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final RainbowColor color;
  const _HelpCard({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: color.color.withValues(alpha: 0.45), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any object with this color is okay!',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.darkColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: color.examples
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        e,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF333355),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Child Dialog
// ─────────────────────────────────────────────
class _ChildDialog extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButton;

  const _ChildDialog({
    required this.emoji,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333366),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: const Color(0xFF666688),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onButton,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B6DFF), Color(0xFF6C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Camera Screen
// ─────────────────────────────────────────────
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _initialized = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    debugPrint('[CameraScreen] Initializing camera: ${widget.camera.name}');
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      debugPrint(
          '[CameraScreen] Camera initialized ok. isInitialized=${_controller!.value.isInitialized}');
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('[CameraScreen] _initCamera error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    debugPrint('[CameraScreen] dispose — controller disposed');
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    debugPrint(
        '[CameraScreen] _capture called. initialized=$_initialized capturing=$_capturing');

    if (_capturing) {
      debugPrint('[CameraScreen] Already capturing — ignored');
      return;
    }
    if (_controller == null) {
      debugPrint('[CameraScreen] Controller is null — abort');
      return;
    }
    if (!_controller!.value.isInitialized) {
      debugPrint('[CameraScreen] Controller not initialized — abort');
      return;
    }
    if (_controller!.value.isTakingPicture) {
      debugPrint(
          '[CameraScreen] Already taking picture (controller flag) — abort');
      return;
    }

    setState(() => _capturing = true);

    // ── FtakePicture with 5s timeout ────────────────────────────────────────
    XFile xfile;
    try {
      debugPrint('[CameraScreen] Calling takePicture()');
      xfile = await _controller!
          .takePicture()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('takePicture timed out after 5s');
      });
      debugPrint('[CameraScreen] takePicture() returned path: ${xfile.path}');
    } catch (e) {
      debugPrint('[CameraScreen] takePicture() ERROR: $e');
      if (mounted) {
        setState(() => _capturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture image. Please try again.'),
            backgroundColor: Color(0xFF6C4DFF),
          ),
        );
      }
      return;
    }

    // ── Verify bytes on web; verify file on native ─────────────────────────
    if (kIsWeb) {
      debugPrint(
          '[CameraScreen] Web: skipping file verification, popping XFile');
      if (mounted) Navigator.pop(context, xfile);
      return;
    }

    try {
      final file = File(xfile.path);
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : 0;
      debugPrint(
          '[CameraScreen] Native: file exists=$exists  size=$size  path=${xfile.path}');
      if (exists && size > 0) {
        if (mounted) Navigator.pop(context, xfile);
      } else {
        debugPrint(
            '[CameraScreen] Native: file missing or empty after capture');
        if (mounted) {
          setState(() => _capturing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file not saved. Please try again.'),
              backgroundColor: Color(0xFF6C4DFF),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[CameraScreen] Native file check error: $e');
      // If file check itself throws, still pop with the XFile — better to try analysis
      if (mounted) Navigator.pop(context, xfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_photography,
                      color: Colors.white70, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Camera not available',
                    style:
                        GoogleFonts.fredoka(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.fredoka(
                          color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ],
              ),
            )
          else if (!_initialized)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else ...[
            CameraPreview(_controller!),

            // Top bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Point at a colored object!',
                      style: GoogleFonts.fredoka(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Capture button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: const Color(0xFF6C4DFF), width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C4DFF).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _capturing
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(
                                color: Color(0xFF6C4DFF), strokeWidth: 3),
                          )
                        : const Icon(Icons.camera_alt,
                            color: Color(0xFF6C4DFF), size: 38),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
