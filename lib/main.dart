import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animation.dart';
import 'video_exporter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google\'s Weather Frog (Froggy)',
      home: AnimationScreen(),
    );
  }
}

class AnimationScreen extends StatefulWidget {
  @override
  _AnimationScreenState createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  List<FilePair> filePairs = [
    FilePair('fields_day_cloudy_bg.webp', 'fields_day_cloudy_frog.flr'),
    FilePair('fields_day_hazy_bg.webp', 'fields_day_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_day_rainy_frog.flr'),
    FilePair('fields_day_snowy_bg.webp', 'fields_day_snowy_frog.flr'),
    FilePair('fields_day_sunny_bg.webp', 'fields_day_sunny_frog.flr'),
    FilePair('fields_morning_cloudy_bg.webp', 'fields_morning_cloudy_frog.flr'),
    FilePair('fields_morning_hazy_bg.webp', 'fields_morning_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_morning_rainy_frog.flr'), // Missing background
    FilePair('fields_morning_snowy_bg.webp', 'fields_morning_snowy_frog.flr'),
    FilePair('fields_morning_sunny_bg.webp', 'fields_morning_sunny_frog.flr'),
    FilePair('fields_night_hazy_bg.webp', 'fields_night_cloudy_frog.flr'), // Missing background
    FilePair('fields_night_hazy_bg.webp', 'fields_night_hazy_frog.flr'),
    FilePair('fields_night_rainy_bg.webp', 'fields_night_rainy_frog.flr'), // Broken animation
    FilePair('fields_night_snowy_bg.webp', 'fields_night_snowy_frog.flr'),
    FilePair('fields_night_sunny_bg.webp', 'fields_night_sunny_frog.flr'),
    FilePair('fields_sunset_cloudy_bg.webp', 'fields_sunset_cloudy_frog.flr'),
    FilePair('fields_sunset_hazy_bg.webp', 'fields_sunset_hazy_frog.flr'),
    FilePair('fields_sunset_rainy_bg.webp', 'fields_sunset_rainy_frog.flr'),
    FilePair('fields_sunset_snowy_bg.webp', 'fields_sunset_snowy_frog.flr'),
    FilePair('fields_sunset_sunny_bg.webp', 'fields_sunset_sunny_frog.flr'),
    FilePair('hill_day_cloudy_bg.webp', 'hill_day_cloudy_frog.flr'),
    FilePair('hill_day_hazy_bg.webp', 'hill_day_hazy_frog.flr'),
    FilePair('hill_day_rainy_bg.webp', 'hill_day_rainy_frog.flr'),
    FilePair('hill_day_snowy_bg.webp', 'hill_day_snowy_frog.flr'),
    FilePair('hill_day_sunny_bg.webp', 'hill_day_sunny_frog.flr'),
    FilePair('hill_morning_cloudy_bg.webp', 'hill_morning_cloudy_frog.flr'),
    FilePair('hill_morning_hazy_bg.webp', 'hill_morning_hazy_frog.flr'),
    FilePair('hill_morning_rainy_bg.webp', 'hill_morning_rainy_frog.flr'),
    FilePair('hill_morning_snowy_bg.webp', 'hill_morning_snowy_frog.flr'),
    FilePair('hill_day_sunny_bg.webp', 'hill_morning_sunny_frog.flr'), // Missing background
    FilePair('hill_night_cloudy_bg.webp', 'hill_night_cloudy_frog.flr'),
    FilePair('hill_night_hazy_bg.webp', 'hill_night_hazy_frog.flr'),
    FilePair('hill_night_rainy_bg.webp', 'hill_night_rainy_frog.flr'),
    FilePair('hill_night_snowy_bg.webp', 'hill_night_snowy_frog.flr'),
    FilePair('hill_night_sunny_bg.webp', 'hill_night_sunny_frog.flr'),
    FilePair('hill_sunset_sunny_bg.webp', 'hill_sunset_sunny_frog.flr'),
    FilePair('mushroom_day_cloudy_bg.webp', 'mushroom_day_cloudy_frog.flr'),
    FilePair('mushroom_day_hazy_bg.webp', 'mushroom_day_hazy_frog.flr'),
    FilePair('mushroom_day_rainy_bg.webp', 'mushroom_day_rainy_frog.flr'),
    FilePair('mushroom_day_snowy_bg.webp', 'mushroom_day_snowy_frog.flr'),
    FilePair('mushroom_day_sunny_bg.webp', 'mushroom_day_sunny_frog.flr'),
    FilePair('mushroom_morning_cloudy_bg.webp', 'mushroom_morning_cloudy_frog.flr'),
    FilePair('mushroom_morning_hazy_bg.webp', 'mushroom_morning_hazy_frog.flr'),
    FilePair('mushroom_morning_rainy_bg.webp', 'mushroom_morning_rainy_frog.flr'),
    FilePair('mushroom_morning_snowy_bg.webp', 'mushroom_morning_snowy_frog.flr'),
    FilePair('mushroom_morning_sunny_bg.webp', 'mushroom_morning_sunny_frog.flr'),
    FilePair('mushroom_night_cloudy_bg.webp', 'mushroom_night_cloudy_frog.flr'),
    FilePair('mushroom_night_hazy_bg.webp', 'mushroom_night_hazy_frog.flr'),
    FilePair('mushroom_night_rainy_bg.webp', 'mushroom_night_rainy_frog.flr'),
    FilePair('mushroom_night_snowy_bg.webp', 'mushroom_night_snowy_frog.flr'),
    FilePair('mushroom_night_sunny_bg.webp', 'mushroom_night_sunny_frog.flr'),
    FilePair('mushroom_sunset_cloudy_bg.webp', 'mushroom_sunset_cloudy_frog.flr'),
    FilePair('mushroom_sunset_hazy_bg.webp', 'mushroom_sunset_hazy_frog.flr'),
    FilePair('mushroom_sunset_rainy_bg.webp', 'mushroom_sunset_rainy_frog.flr'),
    FilePair('mushroom_sunset_snowy_bg.webp', 'mushroom_sunset_snowy_frog.flr'),
    FilePair('mushroom_sunset_sunny_bg.webp', 'mushroom_sunset_sunny_frog.flr'),
  ];

  int currentIndex = 0;
  late List<FroggyAnimation> froggyAnimations;
  late FroggyAnimation froggyAnimation;

  final GlobalKey _repaintKey = GlobalKey();
  late VideoExporter _exporter;

  @override
  void initState() {
    super.initState();
    froggyAnimations = filePairs.map((pair) {
      return FroggyAnimation(
          backgroundFile: pair.backgroundFile,
          animationFile: pair.animationFile);
    }).toList();

    if (Uri.base.queryParameters['index'] != null) {
      currentIndex = int.parse(Uri.base.queryParameters['index']!);
    }

    froggyAnimation = froggyAnimations[currentIndex];
    _exporter = VideoExporter(_repaintKey);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _nextAnimation();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _previousAnimation();
      return true;
    }
    return false;
  }

  void _nextAnimation() {
    setState(() {
      currentIndex = (currentIndex + 1) % froggyAnimations.length;
      froggyAnimation = froggyAnimations[currentIndex];
    });
  }

  void _previousAnimation() {
    setState(() {
      currentIndex = (currentIndex - 1 + froggyAnimations.length) % froggyAnimations.length;
      froggyAnimation = froggyAnimations[currentIndex];
    });
  }

  Future<void> _showExportDialog() async {
    final ffmpegAvailable = await VideoExporter.isFFmpegAvailable();
    if (!mounted) return;

    final durationNotifier = froggyAnimation.controller.durationNotifier;

    await showDialog<void>(
      context: context,
      builder: (context) => ValueListenableBuilder<double?>(
        valueListenable: durationNotifier,
        builder: (context, loopDuration, _) {
          final durationText = loopDuration != null
              ? '${loopDuration.toStringAsFixed(2)}s (one full loop)'
              : 'Detecting…';

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Export Animation',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!ffmpegAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withAlpha(100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FFmpeg not found. Install FFmpeg and add it to your PATH to export video.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Duration: $durationText',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Exports exactly one seamless loop.\nOutput: ~/Videos/froggy_*.mp4\nRequires FFmpeg in PATH.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Export MP4'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (ffmpegAvailable && loopDuration != null)
                      ? Colors.white
                      : Colors.grey,
                  foregroundColor: Colors.black,
                ),
                onPressed: (ffmpegAvailable && loopDuration != null)
                    ? () {
                        Navigator.pop(context);
                        _startExport(loopDuration, currentIndex);
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startExport(double durationSeconds, int index) async {
    final progressNotifier =
        ValueNotifier<(double, String)>((0.0, 'Starting…'));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<(double, String)>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          final (progress, status) = value;
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Exporting…',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 12),
                Text(status,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                const Text(
                  'Keep the window visible during capture.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );

    final (outputPath, errorLog) = await _exporter.export(
      durationSeconds: durationSeconds,
      fps: 30,
      index: index,
      onProgress: (progress, status) {
        progressNotifier.value = (progress, status);
      },
    );

    if (mounted) Navigator.of(context).pop();
    progressNotifier.dispose();

    if (!mounted) return;

    if (outputPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $outputPath'),
          backgroundColor: const Color(0xFF2A2A2A),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.white,
            onPressed: () =>
                Process.run('explorer', ['/select,', outputPath]),
          ),
        ),
      );
    } else {
      _showErrorLog(errorLog ?? 'Unknown error.');
    }
  }

  void _showErrorLog(String log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Export failed',
            style: TextStyle(color: Colors.redAccent)),
        content: SizedBox(
          width: 560,
          height: 320,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: SelectableText(
                log,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: Stack(
              children: [
                froggyAnimation.getBackground(),
                froggyAnimation.getAnimation(),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Tooltip(
              message: 'Export as video',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _showExportDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.videocam,
                        color: Colors.white70, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

