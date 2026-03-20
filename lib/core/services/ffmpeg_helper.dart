import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FFmpegHelper {
  static final FFmpegHelper _instance = FFmpegHelper._internal();
  factory FFmpegHelper() => _instance;
  FFmpegHelper._internal();

  String? _ffmpegPath;
  String? _ffprobePath;
  bool _isInitialized = false;
  late String _platform;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _platform = Platform.operatingSystem;
      log('Initializing FFmpeg for platform: $_platform');
      await _extractFFmpeg();
      _isInitialized = true;
      return true;
    } catch (e) {
      log('Failed to initialize FFmpeg: $e');
      return false;
    }
  }

  Future<String> get ffmpegPath async {
    if (_ffmpegPath != null && await File(_ffmpegPath!).exists()) {
      return _ffmpegPath!;
    }
    await _extractFFmpeg();
    return _ffmpegPath!;
  }

  /// Get ffprobe path (if available)
  Future<String?> get ffprobePath async {
    if (_ffprobePath != null && await File(_ffprobePath!).exists()) {
      return _ffprobePath!;
    }
    
    // Try to find ffprobe in the same directory as ffmpeg
    try {
      final ffmpegDir = p.dirname(await ffmpegPath);
      final ffprobeName = _platform == 'windows' ? 'ffprobe.exe' : 'ffprobe';
      final probeFile = File(p.join(ffmpegDir, ffprobeName));
      
      if (await probeFile.exists()) {
        await _makeExecutable(probeFile.path);
        _ffprobePath = probeFile.path;
        log('Found ffprobe at: $_ffprobePath');
        return _ffprobePath;
      }
    } catch (e) {
      log('Error finding ffprobe: $e');
    }
    
    return null;
  }

Future<void> _makeExecutable(String path) async {
  if (_platform == 'macos' || _platform == 'linux') {
    try {
      // Set permissions
      await Process.run('chmod', ['755', path]);
      await Process.run('chmod', ['+x', path]);
      
      // Remove quarantine attribute (critical for macOS)
      try {
        await Process.run('xattr', ['-d', 'com.apple.quarantine', path]);
        log('Removed quarantine attribute');
      } catch (e) {
        log('No quarantine attribute to remove');
      }
      
      // Verify permissions
      final stat = await File(path).stat();
      log('Final permissions: ${stat.mode}');
      
    } catch (e) {
      log('Warning: Could not make file executable: $e');
    }
  }
}

  Future<bool> _verifyFFmpeg(String path) async {
    try {
      log('Verifying FFmpeg at: $path');
      
      final file = File(path);
      if (!await file.exists()) {
        log('File does not exist');
        return false;
      }
      
      final stat = await file.stat();
      log('File permissions: ${stat.mode}');
      log('File size: ${stat.size} bytes');
      
      final result = await _runProcess(path, ['-version']);
      log('Exit code: ${result.exitCode}');
      
      if (result.exitCode == 0) {
        log('FFmpeg version: ${result.stdout.toString().split('\n').first}');
        return true;
      } else {
        log('Stderr: ${result.stderr}');
        return false;
      }
    } catch (e) {
      log('FFmpeg verification failed: $e');
      return false;
    }
  }

  Future<void> _extractFFmpeg() async {
    final appDir = await getApplicationSupportDirectory();
    log('App support directory: ${appDir.path}');
    
    final binDir = Directory(p.join(appDir.path, 'bin'));
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
      log('Created bin directory');
    }

    String assetPath;
    String executableName;
    
    if (_platform == 'windows') {
      executableName = 'ffmpeg.exe';
      assetPath = 'assets/bin/windows/ffmpeg.exe';
    } else if (_platform == 'macos') {
      executableName = 'ffmpeg';
      assetPath = 'assets/bin/macos/ffmpeg';
    } else {
      throw Exception('Unsupported platform: $_platform');
    }

    final ffmpegFile = File(p.join(binDir.path, executableName));
    log('Target path: ${ffmpegFile.path}');

    if (await ffmpegFile.exists()) {
      log('Existing ffmpeg found');
      await _makeExecutable(ffmpegFile.path);
      
      if (await _verifyFFmpeg(ffmpegFile.path)) {
        _ffmpegPath = ffmpegFile.path;
        log('Using existing ffmpeg');
        return;
      } else {
        log('Existing ffmpeg invalid, deleting');
        await ffmpegFile.delete();
      }
    }

    try {
      log('Loading from assets: $assetPath');
      final byteData = await rootBundle.load(assetPath);
      log('Asset loaded, size: ${byteData.lengthInBytes} bytes');
      
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      await ffmpegFile.writeAsBytes(bytes);
      log('File written');
      
      await _makeExecutable(ffmpegFile.path);
      
      if (!await _verifyFFmpeg(ffmpegFile.path)) {
        throw Exception('FFmpeg binary verification failed after extraction');
      }

      _ffmpegPath = ffmpegFile.path;
      log('FFmpeg successfully installed at: $_ffmpegPath');
      
    } catch (e) {
      log('Error extracting ffmpeg: $e');
      rethrow;
    }
  }

  Future<ProcessResult> _runProcess(String executable, List<String> arguments) async {
    try {
      if (_platform == 'windows') {
        return await Process.run(executable, arguments, runInShell: true);
      } else {
        try {
          return await Process.run(executable, arguments, runInShell: false);
        } catch (e) {
          log('Fallback to shell: $e');
          return await Process.run(executable, arguments, runInShell: true);
        }
      }
    } catch (e) {
      log('Process run error: $e');
      rethrow;
    }
  }

  Future<Process> startFFmpeg(List<String> arguments) async {
    final path = await ffmpegPath;
    log('Starting: $path ${arguments.join(' ')}');
    
    try {
      if (_platform == 'windows') {
        return await Process.start(path, arguments, runInShell: true);
      } else {
        try {
          return await Process.start(path, arguments, runInShell: false);
        } catch (e) {
          log('Fallback to shell: $e');
          return await Process.start(path, arguments, runInShell: true);
        }
      }
    } catch (e) {
      log('Process start error: $e');
      rethrow;
    }
  }

  Future<ProcessResult> runFFmpeg(List<String> arguments) async {
    final path = await ffmpegPath;
    return await _runProcess(path, arguments);
  }

  Future<bool> get isAvailable async {
    try {
      await ffmpegPath;
      return true;
    } catch (_) {
      return false;
    }
  }
}