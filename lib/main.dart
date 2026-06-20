import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'services/tts_service.dart';
import 'services/audio_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/hunt_screen.dart';
import 'screens/result_screen.dart';
import 'screens/celebration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await TtsService().init();
  // Instantiate AudioService early so its WidgetsBindingObserver is
  // registered before the first frame — this ensures app-lifecycle events
  // (pause, detach, hide) are caught from the very start.
  AudioService();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: const TwinkleApp(),
    ),
  );
}

class TwinkleApp extends StatelessWidget {
  const TwinkleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Twinkle's Rainbow Hunt",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C4DFF)),
        useMaterial3: true,
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const _AppNavigator(),
    );
  }
}

class _AppNavigator extends StatelessWidget {
  const _AppNavigator();

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameProvider>().gameState;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildScreen(gameState),
    );
  }

  Widget _buildScreen(GameState state) {
    switch (state) {
      case GameState.welcome:
        return const WelcomeScreen(key: ValueKey('welcome'));
      case GameState.hunting:
        return const HuntScreen(key: ValueKey('hunt'));
      case GameState.analyzing:
        return const AnalyzingScreen(key: ValueKey('analyzing'));
      case GameState.success:
        return const SuccessScreen(key: ValueKey('success'));
      case GameState.failure:
        return const FailureScreen(key: ValueKey('failure'));
      case GameState.celebration:
        return const CelebrationScreen(key: ValueKey('celebration'));
    }
  }
}
