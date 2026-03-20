import 'dart:async';
import 'dart:io';
import 'package:ffmepg_compress_video/core/services/ffmpeg_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:logging/logging.dart';
import '../youtube_options.dart';
import 'youtube_event.dart';
import 'youtube_state.dart';

const _kYoutubeOutputDirKey = 'youtube_output_dir';

class YoutubeBloc extends Bloc<YoutubeEvent, YoutubeState> {
  late YoutubeExplode _yt;
  final FFmpegHelper _ffmpegHelper = FFmpegHelper();

  YoutubeBloc() : super(const YoutubeState()) {
    _initYoutube();

    on<UrlChanged>(_onUrlChanged);
    on<ValidateUrlRequested>(_onValidateUrl);
    on<PickOutputDirRequested>(_onPickOutputDir);
    on<OptionsChanged>(_onOptionsChanged);
    on<DownloadRequested>(_onDownload);
    on<RevealInFinderRequested>(_onReveal);
    on<ResetRequested>(_onReset);

    _hydrateOutputDir();
  }

  void _initYoutube() {
    _yt = YoutubeExplode();

    // Enable logging for debugging if needed
    Logger.root.level = Level.WARNING;
    Logger.root.onRecord.listen((record) {
      if (record.error != null) {
        print('YoutubeExplode error: ${record.error}');
      }
    });
  }

  Future<void> _hydrateOutputDir() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_kYoutubeOutputDirKey);
      if (saved != null && saved.isNotEmpty) {
        emit(state.copyWith(outputDirPath: saved));
      }
    } catch (_) {}
  }

  Future<void> _persistOutputDir(String path) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kYoutubeOutputDirKey, path);
    } catch (_) {}
  }

  void _onUrlChanged(UrlChanged event, Emitter<YoutubeState> emit) {
    emit(state.copyWith(
      url: event.url,
      videoTitle: null,
      videoAuthor: null,
      videoDuration: null,
      thumbnailUrl: null,
      output: null,
      error: null,
    ));
  }

  Future<void> _onValidateUrl(
      ValidateUrlRequested e, Emitter<YoutubeState> emit) async {
    if (state.url == null || state.url!.isEmpty) {
      emit(state.copyWith(error: 'Please enter a YouTube URL'));
      return;
    }

    emit(state.copyWith(
        isValidating: true,
        error: null,
        log: '🔍 Validating URL...\n${state.log}'));

    try {
      // Try to get video info
      final video = await _yt.videos.get(state.url!);

      String duration = 'Live/Unknown';
      if (video.duration != null) {
        final d = video.duration!;
        if (d.inHours > 0) {
          duration = '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
        } else if (d.inMinutes > 0) {
          duration = '${d.inMinutes}m ${d.inSeconds % 60}s';
        } else {
          duration = '${d.inSeconds}s';
        }
      }

      emit(state.copyWith(
        isValidating: false,
        videoTitle: video.title,
        videoAuthor: video.author,
        videoDuration: duration,
        thumbnailUrl: video.thumbnails.standardResUrl,
        log:
            '✅ Video found: ${video.title}\n📺 Channel: ${video.author}\n⏱️ Duration: $duration\n${state.log}',
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isValidating: false,
        error: 'Invalid YouTube URL or video not available',
        log: '❌ Validation failed: $e\n${state.log}',
      ));
    }
  }

  Future<void> _onPickOutputDir(
      PickOutputDirRequested e, Emitter<YoutubeState> emit) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose download folder',
      );
      if (path == null) return;
      await _persistOutputDir(path);
      emit(state.copyWith(outputDirPath: path));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick output directory: $e'));
    }
  }

  void _onOptionsChanged(OptionsChanged e, Emitter<YoutubeState> emit) {
    emit(state.copyWith(options: e.options));
  }

Future<void> _onDownload(
    DownloadRequested e, Emitter<YoutubeState> emit) async {
  if (state.url == null || state.videoTitle == null) {
    emit(state.copyWith(error: 'Please validate a URL first'));
    return;
  }

  emit(state.copyWith(
    isProcessing: true,
    progress: 0.0,
    log: '📥 Starting download...\n${state.log}',
    error: null,
    output: null,
  ));

  try {
    final logBuffer = StringBuffer();

    // Get output directory
    final outputDir =
        state.outputDirPath ?? (await getApplicationSupportDirectory()).path;

    // Sanitize filename (remove invalid characters)
    String safeTitle = state.videoTitle!
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Get video manifest
    logBuffer.writeln('Fetching stream manifest...');
    final manifest = await _yt.videos.streams.getManifest(state.url!);

    File outputFile;

    if (state.options.format == DownloadFormat.audio) {
      // AUDIO MODE: Use audio-only stream directly (MUCH FASTER)
      logBuffer.writeln('Downloading audio stream...');

      // Get audio-only streams
      final audioStreams = manifest.audioOnly.toList();
      
      if (audioStreams.isEmpty) {
        throw Exception('No audio stream available');
      }

      // Sort by bitrate (highest first)
      audioStreams.sort((a, b) => 
          b.bitrate!.bitsPerSecond.compareTo(a.bitrate!.bitsPerSecond));

      // Select stream based on user's bitrate preference
      AudioStreamInfo selectedStream;
      if (state.options.audioBitrate != null) {
        final targetBitrate = int.tryParse(
            state.options.audioBitrate!.replaceAll('kbps', '')) ?? 192;
        
        // Find closest matching bitrate
        selectedStream = audioStreams.reduce((a, b) {
          final aDiff = (a.bitrate!.kiloBitsPerSecond - targetBitrate).abs();
          final bDiff = (b.bitrate!.kiloBitsPerSecond - targetBitrate).abs();
          return aDiff < bDiff ? a : b;
        });
      } else {
        // Use highest bitrate
        selectedStream = audioStreams.first;
      }

      logBuffer.writeln('Audio quality: ${selectedStream.bitrate} kbps');
      logBuffer.writeln('Container: ${selectedStream.container.name}');

      // Download audio to temp file
      final tempFile = File(p.join(outputDir, 'temp_audio_$timestamp.${selectedStream.container.name}'));
      outputFile = File(p.join(outputDir, '${safeTitle}_audio_$timestamp.mp3'));

      emit(state.copyWith(
          progress: 0.1, 
          log: '${state.log}📥 Downloading audio stream...\n'
      ));

      final stream = await _yt.videos.streams.get(selectedStream);
      final sink = tempFile.openWrite();

      int totalBytes = selectedStream.size?.totalBytes ?? 0;
      int downloadedBytes = 0;
      int lastProgress = 0;

      await for (var chunk in stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0) {
          final progressPercent = ((downloadedBytes / totalBytes) * 100).round();
          if (progressPercent > lastProgress) {
            lastProgress = progressPercent;
            final downloadProgress = (downloadedBytes / totalBytes); // 100% for download
            emit(state.copyWith(progress: downloadProgress));
            
            if (progressPercent % 10 == 0) {
              logBuffer.writeln('Download progress: $progressPercent%');
            }
          }
        }
      }
      await sink.close();

      // Convert to MP3 using FFmpeg
      if (selectedStream.container.name.toLowerCase() != 'mp3') {
        emit(state.copyWith(
          progress: 0.9,
          log: '${state.log}🔄 Converting to MP3...\n'
        ));

        final args = [
          '-y',
          '-i', tempFile.path,
          '-codec:a', 'libmp3lame',
          '-b:a', state.options.audioBitrate?.replaceAll('kbps', 'k') ?? '192k',
          '-map_metadata', '0',
          '-id3v2_version', '3',
          outputFile.path,
        ];

        final proc = await _ffmpegHelper.startFFmpeg(args);
        final exitCode = await proc.exitCode;
        
        if (exitCode != 0) {
          throw Exception('FFmpeg conversion failed with exit code $exitCode');
        }

        // Clean up temp file
        await tempFile.delete();
      } else {
        // Already MP3, just rename
        await tempFile.rename(outputFile.path);
      }

      logBuffer.writeln('Audio download complete!');
      
    } else {
      // VIDEO MODE: Download muxed stream directly
      logBuffer.writeln('Downloading video stream...');

      // Helper method to parse video quality label and get height
      int parseVideoHeight(String qualityLabel) {
        final match = RegExp(r'(\d+)p').firstMatch(qualityLabel);
        return match != null ? int.parse(match.group(1)!) : 0;
      }

      // Get muxed streams (video + audio together)
      final muxedStreams = manifest.muxed
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();

      if (muxedStreams.isEmpty) {
        throw Exception(
            'No muxed video stream available. Try a different quality option.');
      }

      // Filter by selected quality if specified
      Iterable<MuxedStreamInfo> filteredStreams = muxedStreams;
      if (state.options.videoQuality != null) {
        final targetHeight =
            int.tryParse(state.options.videoQuality!.replaceAll('p', '')) ??
                0;
        filteredStreams = muxedStreams.where((s) {
          final height = parseVideoHeight(s.videoQualityLabel);
          return height == targetHeight;
        });
      }

      if (filteredStreams.isEmpty) {
        filteredStreams = muxedStreams; // Fallback to all streams
      }

      // Get best quality stream
      final videoStream = filteredStreams.reduce((a, b) {
        final aHeight = parseVideoHeight(a.videoQualityLabel);
        final bHeight = parseVideoHeight(b.videoQualityLabel);

        if (aHeight != bHeight) {
          return aHeight > bHeight ? a : b;
        }

        // If same height, prefer higher framerate
        final aHas60 = a.videoQualityLabel.contains('60');
        final bHas60 = b.videoQualityLabel.contains('60');

        if (aHas60 != bHas60) {
          return aHas60 ? a : b;
        }

        // If still same, compare by bitrate
        return a.bitrate!.bitsPerSecond > b.bitrate!.bitsPerSecond ? a : b;
      });

      logBuffer.writeln('Video quality: ${videoStream.videoQualityLabel}');
      logBuffer.writeln('Container: ${videoStream.container.name}');

      outputFile = File(p.join(outputDir, '${safeTitle}_video_$timestamp.mp4'));

      // Download video with progress
      emit(state.copyWith(
          progress: 0.1, log: '${state.log}📥 Downloading video...\n'));

      final stream = await _yt.videos.streams.get(videoStream);
      final sink = outputFile.openWrite();

      // Get total size for progress
      int totalBytes = videoStream.size?.totalBytes ?? 0;
      int downloadedBytes = 0;

      await for (var chunk in stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0) {
          final downloadProgress =
              (downloadedBytes / totalBytes).clamp(0.0, 1.0);
          emit(state.copyWith(progress: downloadProgress));
        }
      }
      await sink.close();
    }

    emit(state.copyWith(
      isProcessing: false,
      progress: 1.0,
      output: outputFile,
      log:
          '✅ Download complete!\n📁 ${outputFile.path}\n${logBuffer.toString()}${state.log}',
    ));
  } catch (e) {
    emit(state.copyWith(
      isProcessing: false,
      error: 'Download failed: $e',
      log: '❌ Error: $e\n${state.log}',
    ));
  }
}

  Future<void> _onReveal(
      RevealInFinderRequested e, Emitter<YoutubeState> emit) async {
    if (state.output != null) {
      final path = state.output!.path;
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      }
    }
  }

  void _onReset(ResetRequested e, Emitter<YoutubeState> emit) {
    emit(const YoutubeState());
    _hydrateOutputDir();
  }

  @override
  Future<void> close() {
    _yt.close();
    return super.close();
  }
}
