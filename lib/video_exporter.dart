import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class VideoExporter {
  final GlobalKey repaintKey;

  VideoExporter(this.repaintKey);

  static Future<bool> isFFmpegAvailable() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // Returns (outputPath, null) on success, (null, errorLog) on failure.
  Future<(String?, String?)> export({
    required double durationSeconds,
    required int fps,
    required int index,
    required void Function(double progress, String status) onProgress,
  }) async {
    final frameDir = Directory('${Directory.systemTemp.path}\\froggy_export_$index');
    await frameDir.create(recursive: true);

    try {
      final captureInterval = 1.0 / fps;
      double nextCapture = 0.0;
      int frameIndex = 0;

      final startTime = DateTime.now();

      while (true) {
        await SchedulerBinding.instance.endOfFrame;

        final elapsed =
            DateTime.now().difference(startTime).inMicroseconds / 1e6;
        if (elapsed >= durationSeconds) break;

        if (elapsed >= nextCapture) {
          nextCapture += captureInterval;

          final (bytes, _, __) = await _captureFrame();
          if (bytes != null) {
            final file = File(
                '${frameDir.path}\\frame_${frameIndex.toString().padLeft(4, '0')}.png');
            await file.writeAsBytes(bytes);
            frameIndex++;

            onProgress(
              elapsed / durationSeconds * 0.8,
              'Capturing… ${elapsed.toStringAsFixed(2)}s / ${durationSeconds.toStringAsFixed(2)}s',
            );
          }
        }
      }

      if (frameIndex == 0) {
        return (null, 'No frames were captured.');
      }

      final outputPath = '${_videosPath()}\\froggy_$index.mp4';

      onProgress(0.85, 'Encoding video…');

      final result = await Process.run('ffmpeg', [
        '-y',
        '-framerate', fps.toString(),
        '-i', '${frameDir.path}\\frame_%04d.png',
        '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-crf', '18',
        '-r', fps.toString(),
        outputPath,
      ]);

      final outputFile = File(outputPath);
      final succeeded = result.exitCode == 0 &&
          outputFile.existsSync() &&
          outputFile.lengthSync() > 0;

      if (!succeeded) {
        final log = StringBuffer();
        log.writeln('FFmpeg exit code: ${result.exitCode}');
        log.writeln('Frames captured: $frameIndex');
        log.writeln('Output path: $outputPath');
        if ((result.stderr as String).isNotEmpty) {
          log.writeln('\n--- stderr ---');
          log.write(result.stderr);
        }
        if ((result.stdout as String).isNotEmpty) {
          log.writeln('\n--- stdout ---');
          log.write(result.stdout);
        }
        return (null, log.toString());
      }

      onProgress(1.0, 'Done!');
      return (outputPath, null);
    } finally {
      try {
        await frameDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<(Uint8List?, int?, int?)> _captureFrame() async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return (null, null, null);

      final image = await boundary.toImage(pixelRatio: 1.0);
      final w = image.width;
      final h = image.height;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return (null, null, null);
      return (byteData.buffer.asUint8List(), w, h);
    } catch (_) {
      return (null, null, null);
    }
  }

  static String _videosPath() {
    final home = Platform.environment['USERPROFILE'] ?? '';
    final dir = Directory('$home\\Videos');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }
}
