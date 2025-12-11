import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:ffmepg_compress_video/features/compressor/compression_options.dart' show CompressionOptions;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FfmpegResult {
  final File? output;
  final int exitCode;
  final String? error;
  const FfmpegResult({this.output, required this.exitCode, this.error});
}

class FfmpegProcessService {
  Future<File> buildOutputFile(File input, {String? directory}) async {
    final dirPath = directory ?? (await getTemporaryDirectory()).path;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final base = p.basenameWithoutExtension(input.path);
    return File(p.join(dirPath, '${base}_compressed_$ts.mp4'));
  }

  String _scaleFilter(int? w, int? h) {
    if (w == null && h == null) return '';
    if (w != null && h != null) return 'scale=$w:$h';
    if (w != null) return 'scale=$w:-2';       // keep AR
    return 'scale=-2:$h';
  }

  List<String> buildArgs({
    required File input,
    required File output,
    required CompressionOptions opt,
  }) {
    return <String>[
      '-y',
      '-i', input.path,
      '-c:v', opt.vCodec,
      '-crf', opt.crf.toString(),
      '-preset', opt.preset,
      if (opt.width != null || opt.height != null) ...[
        '-vf', _scaleFilter(opt.width, opt.height),
      ],
      '-c:a', 'aac',
      '-b:a', '${opt.audioBitrateK}k',
      output.path,
    ];
  }

  Future<double?> probeDurationSeconds(File input) async {
    // Prefer ffprobe (more reliable)
    try {
      final r = await Process.run(
        'ffprobe',
        ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', input.path],
        runInShell: true,
      );
      if (r.exitCode == 0) {
        final v = double.tryParse((r.stdout as String).trim());
        if (v != null && v > 0) return v;
      }
    } catch (_) {}
    // Fallback: parse `ffmpeg -i` stderr
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

  /// Run ffmpeg (from PATH). Streams logs + progress (0..1).
  Future<FfmpegResult> compress({
    required File input,
    required CompressionOptions options,
    String? outputDirectory,
    void Function(String line)? onLog,
    void Function(double progress01)? onProgress,
  }) async {
    final out = await buildOutputFile(input, directory: outputDirectory);
    final args = buildArgs(input: input, output: out, opt: options);

    final total = await probeDurationSeconds(input);
    double last = -1;

    final proc = await Process.start('ffmpeg', args, runInShell: true);

    // stdout (rarely used)
    final subOut = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) => onLog?.call(l));

    // stderr contains progress
    final subErr = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((l) {
      onLog?.call(l);
      final m = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(l);
      if (m != null && total != null && total > 0) {
        final h = double.parse(m.group(1)!);
        final min = double.parse(m.group(2)!);
        final s = double.parse(m.group(3)!);
        final cur = h * 3600 + min * 60 + s;
        final p01 = (cur / total).clamp(0.0, 1.0);
        if ((p01 * 100).floor() != (last * 100).floor()) {
          last = p01;
          onProgress?.call(p01);
        }
      }
    });

    final code = await proc.exitCode;
    await subOut.cancel();
    await subErr.cancel();

    if (code == 0 && await out.exists()) {
      onProgress?.call(1.0);
      onLog?.call('✅ Done: ${out.path}');
      return FfmpegResult(output: out, exitCode: code);
    }
    return FfmpegResult(output: null, exitCode: code, error: 'ffmpeg exitCode=$code');
  }
}
