import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FfmpegResult {
  final File? output;
  final int exitCode;
  final String? error;
  final String? outputDir; // for multi-file outputs (e.g., frames)
  const FfmpegResult({this.output, required this.exitCode, this.error, this.outputDir});
}

class FfmpegProcessService {
  Future<File> buildOutputFile({
    required File input,
    String? directory,
    required String suffix,
    required String newExtension, // 'mp4' | 'gif' | 'mp3' | etc.
  }) async {
    final dirPath = directory ?? (await getTemporaryDirectory()).path;
    final name = p.basenameWithoutExtension(input.path);
    final outPath = p.join(dirPath, '${name}_$suffix.${newExtension.toLowerCase()}');
    return File(outPath);
  }

  Future<String> ensureOutputDir({String? directory, required String fallbackName}) async {
    final dirPath = directory ?? (await getTemporaryDirectory()).path;
    final out = p.join(dirPath, fallbackName);
    await Directory(out).create(recursive: true);
    return out;
  }

  String patternIn(String dir, String ext) => p.join(dir, 'frame_%05d.$ext'); // frame_00001.png...

  String scaleFilter({int? width, int? height}) {
    if (width == null && height == null) return '';
    if (width != null && height != null) return 'scale=$width:$height';
    if (width != null) return 'scale=$width:-2';
    return 'scale=-2:$height';
  }

  Future<double?> probeDurationSeconds(File input) async {
    try {
      final r = await Process.run('ffprobe',
          ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', input.path],
          runInShell: true);
      if (r.exitCode == 0) {
        final v = double.tryParse((r.stdout as String).trim());
        if (v != null && v > 0) return v;
      }
    } catch (_) {}
    try {
      final r = await Process.run('ffmpeg', ['-i', input.path], runInShell: true);
      final out = '${r.stderr}${r.stdout}';
      final m = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.?\d*)').firstMatch(out);
      if (m != null) {
        final h = double.parse(m.group(1)!);
        final mnt = double.parse(m.group(2)!);
        final s = double.parse(m.group(3)!);
        return h * 3600 + mnt * 60 + s;
      }
    } catch (_) {}
    return null;
  }

  /// One-output run with progress parsed from `time=`.
  Future<FfmpegResult> runWithProgress({
    required List<String> args,
    required File expectedOutput,
    void Function(String line)? onLog,
    void Function(double progress01)? onProgress,
    double? totalSeconds,
  }) async {
    final proc = await Process.start('ffmpeg', args, runInShell: true);
    double last = -1;
    final subOut = proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(onLog ?? (_) {});
    final subErr = proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      onLog?.call(l);
      final m = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(l);
      if (m != null && totalSeconds != null && totalSeconds > 0) {
        final h = double.parse(m.group(1)!);
        final min = double.parse(m.group(2)!);
        final s = double.parse(m.group(3)!);
        final cur = h * 3600 + min * 60 + s;
        final p01 = (cur / totalSeconds).clamp(0.0, 1.0);
        if ((p01 * 100).floor() != (last * 100).floor()) {
          last = p01; onProgress?.call(p01);
        }
      }
    });

    final code = await proc.exitCode;
    await subOut.cancel(); await subErr.cancel();

    if (code == 0 && await expectedOutput.exists()) {
      onProgress?.call(1.0);
      onLog?.call('✅ Done: ${expectedOutput.path}');
      return FfmpegResult(output: expectedOutput, exitCode: code);
    }
    return FfmpegResult(output: null, exitCode: code, error: 'ffmpeg exitCode=$code');
  }

  /// Multi-output (e.g., images) or container copy; doesn’t check a single file.
  Future<FfmpegResult> runLoose({
    required List<String> args,
    String? outputDir,
    void Function(String line)? onLog,
    void Function(double progress01)? onProgress,
    double? totalSeconds,
  }) async {
    final proc = await Process.start('ffmpeg', args, runInShell: true);
    double last = -1;
    final subOut = proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(onLog ?? (_) {});
    final subErr = proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      onLog?.call(l);
      final m = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(l);
      if (m != null && totalSeconds != null && totalSeconds > 0) {
        final h = double.parse(m.group(1)!);
        final min = double.parse(m.group(2)!);
        final s = double.parse(m.group(3)!);
        final cur = h * 3600 + min * 60 + s;
        final p01 = (cur / totalSeconds).clamp(0.0, 1.0);
        if ((p01 * 100).floor() != (last * 100).floor()) {
          last = p01; onProgress?.call(p01);
        }
      }
    });

    final code = await proc.exitCode;
    await subOut.cancel(); await subErr.cancel();

    if (code == 0) {
      onProgress?.call(1.0);
      onLog?.call('✅ Completed.');
      return FfmpegResult(output: null, exitCode: code, outputDir: outputDir);
    }
    return FfmpegResult(output: null, exitCode: code, error: 'ffmpeg exitCode=$code', outputDir: outputDir);
  }
}
