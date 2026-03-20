import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmepg_compress_video/features/audio_compressor/audio_compressor.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmepg_compress_video/core/services/ffmpeg_helper.dart';
import 'audio_compressor_event.dart';
import 'audio_compressor_state.dart';

const _kAudioOutputDirKey = 'audio_compressor_output_dir';

class AudioCompressorBloc extends Bloc<AudioCompressorEvent, AudioCompressorState> {
  final FFmpegHelper _ffmpegHelper = FFmpegHelper();
  Process? _previewProcess;

  AudioCompressorBloc() : super(const AudioCompressorState()) {
    on<PickAudioRequested>(_onPickAudio);
    on<PickOutputDirRequested>(_onPickOutputDir);
    on<AudioOptionsChanged>(_onOptionsChanged);
    on<CompressAudioRequested>(_onCompress);
    on<PreviewAudioRequested>(_onPreview);
    on<StopPreviewRequested>(_onStopPreview);
    on<RevealInFinderRequested>(_onReveal);
    on<ResetRequested>(_onReset);

    _hydrateOutputDir();
  }

  Future<void> _hydrateOutputDir() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_kAudioOutputDirKey);
      if (saved != null && saved.isNotEmpty) {
        emit(state.copyWith(outputDirPath: saved));
      }
    } catch (_) {}
  }

  Future<void> _persistOutputDir(String path) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kAudioOutputDirKey, path);
    } catch (_) {}
  }

  Future<void> _onPickAudio(
    PickAudioRequested e, Emitter<AudioCompressorState> emit) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    final file = File(path);
    
    // Show immediate info with filename
    final fileName = p.basenameWithoutExtension(path);
    emit(state.copyWith(
      inputFile: file,
      outputFile: null,
      isLoading: true,
      title: fileName, // Show filename immediately
      log: '📂 Loading audio file: ${p.basename(path)}\n${state.log}',
    ));

    // Extract metadata in background
    await _extractMetadata(file, emit);

  } catch (e) {
    emit(state.copyWith(
      error: 'Failed to load audio: $e',
      isLoading: false,
    ));
  }
}

  Future<void> _extractMetadata(File file, Emitter<AudioCompressorState> emit) async {
  try {
    // Use ffmpeg to get metadata instead of ffprobe
    final result = await _ffmpegHelper.runFFmpeg(['-i', file.path]);
    
    // FFmpeg outputs metadata to stderr
    final output = result.stderr.toString();
    
    // Parse title
    String? title;
    String? artist;
    String? album;
    
    // Try to find metadata in the output
    final titleMatch = RegExp(r'title\s*:\s*(.+?)(?:\n|$)').firstMatch(output);
    if (titleMatch != null) title = titleMatch.group(1)?.trim();
    
    final artistMatch = RegExp(r'artist\s*:\s*(.+?)(?:\n|$)').firstMatch(output);
    if (artistMatch != null) artist = artistMatch.group(1)?.trim();
    
    final albumMatch = RegExp(r'album\s*:\s*(.+?)(?:\n|$)').firstMatch(output);
    if (albumMatch != null) album = albumMatch.group(1)?.trim();
    
    // Fallback to filename if no title
    if (title == null || title.isEmpty) {
      title = p.basenameWithoutExtension(file.path);
    }
    
    // Parse duration
    int? duration;
    final durationMatch = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.?\d*)').firstMatch(output);
    if (durationMatch != null) {
      final h = double.parse(durationMatch.group(1)!);
      final m = double.parse(durationMatch.group(2)!);
      final s = double.parse(durationMatch.group(3)!);
      duration = (h * 3600 + m * 60 + s).round();
    }
    
    // Parse bitrate
    int? bitrate;
    final bitrateMatch = RegExp(r'bitrate:\s*(\d+)\s*kb/s').firstMatch(output);
    if (bitrateMatch != null) {
      bitrate = int.parse(bitrateMatch.group(1)!);
    }
    
    // Parse sample rate
    int? sampleRate;
    final sampleRateMatch = RegExp(r'(\d+)\s*Hz').firstMatch(output);
    if (sampleRateMatch != null) {
      sampleRate = int.parse(sampleRateMatch.group(1)!);
    }
    
    // Check for album art (attached picture)
    bool hasArt = output.contains('attached pic') || 
                  output.contains('Video: mjpeg') ||
                  output.contains('Video: jpeg');
    
    // Extract album art if available
    Uint8List? albumArtThumbnail;
    if (hasArt) {
      try {
        albumArtThumbnail = await _extractAlbumArt(file);
      } catch (e) {
        print('Failed to extract album art: $e');
      }
    }
    
    // Build log message
    final logMsg = StringBuffer();
    logMsg.writeln('📊 Bitrate: ${bitrate ?? '?'} kbps');
    logMsg.writeln('📈 Sample Rate: ${sampleRate ?? '?'} Hz');
    logMsg.writeln('🎨 Album Art: ${hasArt ? 'Yes' : 'No'}');
    if (title != null) logMsg.writeln('🎵 Title: $title');
    if (artist != null) logMsg.writeln('👤 Artist: $artist');
    if (album != null) logMsg.writeln('💿 Album: $album');

    emit(state.copyWith(
      isLoading: false,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      originalBitrate: bitrate,
      originalSampleRate: sampleRate,
      hasAlbumArt: hasArt,
      albumArtThumbnail: albumArtThumbnail,
      log: '${logMsg.toString()}${state.log}',
    ));
    
  } catch (e) {
    print('Metadata extraction error: $e');
    // Fallback: just show filename
    final fileName = p.basenameWithoutExtension(file.path);
    emit(state.copyWith(
      isLoading: false,
      title: fileName,
      log: '${state.log}⚠️ Could not extract metadata: $e\n',
    ));
  }
}

  Future<Uint8List?> _extractAlbumArt(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempImageFile = File(p.join(tempDir.path, 'temp_album_art.jpg'));
      
      final args = [
        '-y',
        '-i', file.path,
        '-an',
        '-vcodec', 'copy',
        '-frames:v', '1',
        '-f', 'image2',
        tempImageFile.path,
      ];
      
      final result = await _ffmpegHelper.runFFmpeg(args);
      
      if (result.exitCode == 0 && await tempImageFile.exists()) {
        final bytes = await tempImageFile.readAsBytes();
        await tempImageFile.delete();
        return bytes;
      }
    } catch (e) {
      print('Album art extraction error: $e');
    }
    return null;
  }

  Future<void> _onPickOutputDir(
      PickOutputDirRequested e, Emitter<AudioCompressorState> emit) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose output folder',
      );
      if (path == null) return;
      await _persistOutputDir(path);
      emit(state.copyWith(outputDirPath: path));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick output directory: $e'));
    }
  }

  void _onOptionsChanged(
      AudioOptionsChanged e, Emitter<AudioCompressorState> emit) {
    emit(state.copyWith(options: e.options));
  }

  Future<void> _onCompress(
      CompressAudioRequested e, Emitter<AudioCompressorState> emit) async {
    if (state.inputFile == null) {
      emit(state.copyWith(error: 'Please select an audio file first'));
      return;
    }

    emit(state.copyWith(
      isProcessing: true,
      progress: 0.0,
      log: '🎚️ Starting audio compression...\n${state.log}',
      error: null,
      outputFile: null,
    ));

    try {
      final logBuffer = StringBuffer();

      final outputDir = state.outputDirPath ?? 
          (await getApplicationSupportDirectory()).path;

      final inputName = p.basenameWithoutExtension(state.inputFile!.path);
      final safeName = inputName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      String extension;
      switch (state.options.format) {
        case AudioFormat.mp3:
          extension = 'mp3';
          break;
        case AudioFormat.aac:
          extension = 'aac';
          break;
        case AudioFormat.ogg:
          extension = 'ogg';
          break;
        case AudioFormat.m4a:
          extension = 'm4a';
          break;
        case AudioFormat.wav:
          extension = 'wav';
          break;
      }

      final outputFile = File(p.join(
        outputDir, 
        '${safeName}_compressed_$timestamp.$extension'
      ));

      // Build FFmpeg arguments
      final args = ['-y', '-i', state.inputFile!.path];

      // CRITICAL FIX: Map streams based on album art preference
      // This is the key to removing album art
      if (state.options.removeAlbumArt) {
        // Only map audio stream - this removes album art
        args.addAll(['-map', '0:a']);
        logBuffer.writeln('🎨 Removing album art (only audio stream)');
      } else {
        // Map all streams - keeps album art
        args.addAll(['-map', '0']);
        logBuffer.writeln('🎨 Keeping all streams (including album art)');
      }

      // Add trim if specified
      if (state.options.trimSilence) {
        if (state.options.startTime != null) {
          args.addAll(['-ss', state.options.startTime!.toString()]);
        }
        if (state.options.endTime != null) {
          args.addAll(['-to', state.options.endTime!.toString()]);
        }
      }

      // Audio codec
      switch (state.options.format) {
        case AudioFormat.mp3:
          args.addAll(['-codec:a', 'libmp3lame']);
          break;
        case AudioFormat.aac:
          args.addAll(['-codec:a', 'aac']);
          break;
        case AudioFormat.ogg:
          args.addAll(['-codec:a', 'libvorbis']);
          break;
        case AudioFormat.m4a:
          args.addAll(['-codec:a', 'aac']);
          break;
        case AudioFormat.wav:
          args.addAll(['-codec:a', 'pcm_s16le']);
          break;
      }

      // Bitrate
      args.addAll(['-b:a', '${state.options.quality.bitrate}k']);

      // Sample rate
      if (state.options.sampleRate != null) {
        args.addAll(['-ar', state.options.sampleRate!.toString()]);
      }

      // Channel mode
      if (state.options.channelMode != ChannelMode.stereo) {
        args.addAll(['-ac', '1']); // Mono
      } else {
        args.addAll(['-ac', '2']); // Stereo
      }

      // Volume normalization
      if (state.options.normalizeVolume) {
        if (state.options.volumeTarget != null) {
          args.addAll(['-af', 'volume=${state.options.volumeTarget}dB']);
        } else {
          args.addAll(['-af', 'loudnorm']);
        }
      }

      // Remove silence
      if (state.options.removeSilence) {
        final threshold = state.options.silenceThreshold ?? -50;
        args.addAll([
          '-af', 
          'silenceremove=start_periods=1:start_duration=1:start_threshold=${threshold}dB:'
          'detection=peak,aformat=dblp'
        ]);
      }

      // Fade in/out
      if (state.options.fadeInOut && 
          state.options.fadeDuration != null && 
          state.duration != null) {
        final fadeDur = state.options.fadeDuration!;
        if (state.duration! > fadeDur * 2) {
          args.addAll([
            '-af', 
            'afade=t=in:st=0:d=$fadeDur,afade=t=out:st=${state.duration! - fadeDur}:d=$fadeDur'
          ]);
        }
      }

      // Metadata preservation
      if (state.options.preserveMetadata) {
        args.addAll(['-map_metadata', '0']);
        
        // Add ID3 tags for MP3
        if (state.options.format == AudioFormat.mp3) {
          args.addAll(['-id3v2_version', '3']);
        }
      }

      args.add(outputFile.path);

      logBuffer.writeln('FFmpeg command: ffmpeg ${args.join(' ')}');

      // Execute FFmpeg with progress monitoring
      final proc = await _ffmpegHelper.startFFmpeg(args);
      
      int lastProgress = 0;
      
      proc.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        logBuffer.writeln(line);
        
        // Parse progress
        if (state.duration != null && state.duration! > 0) {
          final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(line);
          if (timeMatch != null) {
            final h = double.parse(timeMatch.group(1)!);
            final m = double.parse(timeMatch.group(2)!);
            final s = double.parse(timeMatch.group(3)!);
            final currentSecs = h * 3600 + m * 60 + s;
            final progress = (currentSecs / state.duration!).clamp(0.0, 1.0);
            
            final progressPercent = (progress * 100).round();
            if (progressPercent > lastProgress) {
              lastProgress = progressPercent;
              emit(state.copyWith(progress: progress));
            }
          }
        }
      });

      final exitCode = await proc.exitCode;

      if (exitCode == 0 && await outputFile.exists()) {
        final inputSize = await state.inputFile!.length();
        final outputSize = await outputFile.length();
        final ratio = ((1 - (outputSize / inputSize)) * 100).round();

        emit(state.copyWith(
          isProcessing: false,
          progress: 1.0,
          outputFile: outputFile,
          log: '✅ Compression complete!\n'
               '📁 ${outputFile.path}\n'
               '📊 Size reduced by $ratio%\n'
               '${logBuffer.toString()}${state.log}',
        ));
      } else {
        throw Exception('FFmpeg exited with code $exitCode');
      }

    } catch (e) {
      emit(state.copyWith(
        isProcessing: false,
        error: 'Compression failed: $e',
        log: '❌ Error: $e\n${state.log}',
      ));
    }
  }

  Future<void> _onPreview(
      PreviewAudioRequested e, Emitter<AudioCompressorState> emit) async {
    if (state.inputFile == null) {
      emit(state.copyWith(error: 'Please select an audio file first'));
      return;
    }

    await _stopPreview();

    emit(state.copyWith(
      isPreviewing: true,
      log: '🎵 Previewing audio...\n${state.log}',
    ));

    try {
      _previewProcess = await Process.start(
        'ffplay',
        [
          '-nodisp',
          '-autoexit',
          state.inputFile!.path,
        ],
        runInShell: true,
      );

      _previewProcess!.exitCode.then((code) {
        if (!emit.isDone) {
          emit(state.copyWith(isPreviewing: false));
        }
      });

    } catch (e) {
      emit(state.copyWith(
        isPreviewing: false,
        error: 'Preview failed: $e',
      ));
    }
  }

  Future<void> _onStopPreview(
      StopPreviewRequested e, Emitter<AudioCompressorState> emit) async {
    await _stopPreview();
    emit(state.copyWith(isPreviewing: false));
  }

  Future<void> _stopPreview() async {
    if (_previewProcess != null) {
      _previewProcess!.kill();
      _previewProcess = null;
    }
  }

  Future<void> _onReveal(
      RevealInFinderRequested e, Emitter<AudioCompressorState> emit) async {
    if (state.outputFile != null) {
      final path = state.outputFile!.path;
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      }
    }
  }

  void _onReset(ResetRequested e, Emitter<AudioCompressorState> emit) {
    _stopPreview();
    emit(const AudioCompressorState());
    _hydrateOutputDir();
  }

  @override
  Future<void> close() {
    _stopPreview();
    return super.close();
  }
}