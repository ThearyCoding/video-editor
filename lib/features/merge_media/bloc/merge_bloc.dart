import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/ffmpeg_helper.dart';
import 'merge_event.dart';
import 'merge_state.dart';

const _kMergeOutputDirKey = 'merge_output_dir';

class MergeBloc extends Bloc<MergeEvent, MergeState> {
  final ImagePicker _picker = ImagePicker();
  final FFmpegHelper _ffmpegHelper = FFmpegHelper();

  MergeBloc() : super(const MergeState()) {
    on<PickVideoRequested>(_onPickVideo);
    on<PickImageRequested>(_onPickImage);
    on<PickAudioRequested>(_onPickAudio);
    on<PickOutputDirRequested>(_onPickOutputDir);
    on<MergeOptionsChanged>(_onOptionsChanged);
    on<MergeTypeChanged>(_onMergeTypeChanged);
    on<MergeRequested>(_onMerge);
    on<RevealInFinderRequested>(_onReveal);
    on<ResetRequested>(_onReset);
    _hydrateOutputDir();
  }

  Future<void> _hydrateOutputDir() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_kMergeOutputDirKey);
      if (saved != null && saved.isNotEmpty) {
        emit(state.copyWith(outputDirPath: saved));
      }
    } catch (_) {}
  }

  Future<void> _persistOutputDir(String path) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kMergeOutputDirKey, path);
    } catch (_) {}
  }

  Future<void> _onPickVideo(PickVideoRequested e, Emitter<MergeState> emit) async {
    try {
      final XFile? xf = await _picker.pickVideo(source: ImageSource.gallery);
      if (xf == null) return;
      
      // Clear image file when video is selected
      emit(state.copyWith(
        videoFile: File(xf.path),
        imageFile: null,
        output: null,
        log: '✅ Video selected: ${p.basename(xf.path)}\n${state.log}',
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick video: $e'));
    }
  }

  Future<void> _onPickImage(PickImageRequested e, Emitter<MergeState> emit) async {
    try {
      final XFile? xf = await _picker.pickImage(source: ImageSource.gallery);
      if (xf == null) return;
      
      // Clear video file when image is selected
      emit(state.copyWith(
        imageFile: File(xf.path),
        videoFile: null,
        output: null,
        log: '✅ Image selected: ${p.basename(xf.path)}\n${state.log}',
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick image: $e'));
    }
  }

  Future<void> _onPickAudio(PickAudioRequested e, Emitter<MergeState> emit) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      
      emit(state.copyWith(
        audioFile: File(path),
        output: null,
        log: '✅ Audio selected: ${p.basename(path)}\n${state.log}',
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick audio: $e'));
    }
  }

  Future<void> _onPickOutputDir(PickOutputDirRequested e, Emitter<MergeState> emit) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose output folder for merged video',
      );
      if (path == null) return;
      await _persistOutputDir(path);
      emit(state.copyWith(outputDirPath: path));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick output directory: $e'));
    }
  }

  void _onOptionsChanged(MergeOptionsChanged e, Emitter<MergeState> emit) {
    emit(state.copyWith(options: e.options));
  }

  void _onMergeTypeChanged(MergeTypeChanged e, Emitter<MergeState> emit) {
    emit(state.copyWith(
      mergeType: e.mergeType,
      output: null,
      // Clear the inappropriate file based on type
      videoFile: e.mergeType == MergeType.videoAudio ? state.videoFile : null,
      imageFile: e.mergeType == MergeType.imageAudio ? state.imageFile : null,
    ));
  }

  Future<void> _onMerge(MergeRequested e, Emitter<MergeState> emit) async {
    // Validate based on merge type
    if (state.mergeType == MergeType.videoAudio) {
      if (state.videoFile == null || state.audioFile == null) {
        emit(state.copyWith(error: 'Please select both video and audio files'));
        return;
      }
    } else {
      if (state.imageFile == null || state.audioFile == null) {
        emit(state.copyWith(error: 'Please select both image and audio files'));
        return;
      }
    }

    emit(state.copyWith(
      isProcessing: true,
      progress: 0.0,
      log: '🎬 Starting ${state.mergeType == MergeType.videoAudio ? 'video+audio' : 'image+audio'} merge...\n${state.log}',
      error: null,
      output: null,
    ));

    try {
      final logBuffer = StringBuffer();
      
      // Determine output path
      final outputDir = state.outputDirPath ?? (await getApplicationSupportDirectory()).path;
      
      final inputName = state.mergeType == MergeType.videoAudio
          ? p.basenameWithoutExtension(state.videoFile!.path)
          : p.basenameWithoutExtension(state.imageFile!.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File(p.join(outputDir, '${inputName}_merged_$timestamp.mp4'));

      // Get durations
      final audioDuration = await _getDuration(state.audioFile!.path);
      logBuffer.writeln('Audio duration: ${audioDuration?.toStringAsFixed(2)}s');

      // Build ffmpeg arguments
      final args = <String>['-y'];
      
      if (state.mergeType == MergeType.videoAudio) {
        // Video + Audio merge
        args.addAll(['-i', state.videoFile!.path]);
        args.addAll(['-i', state.audioFile!.path]);
        args.addAll(['-map', '0:v:0']); // Video from first input
        args.addAll(['-map', '1:a:0']); // Audio from second input
        
        final videoDuration = await _getDuration(state.videoFile!.path);
        logBuffer.writeln('Video duration: ${videoDuration?.toStringAsFixed(2)}s');
        
        // Trim if needed
        if (state.options.useShortestAudio && 
            videoDuration != null && 
            audioDuration != null) {
          final shortest = videoDuration < audioDuration ? videoDuration : audioDuration;
          args.addAll(['-t', shortest.toStringAsFixed(3)]);
          logBuffer.writeln('Trimming to shortest duration: ${shortest.toStringAsFixed(2)}s');
        }
        
      } else {
        // Image + Audio merge
        args.addAll(['-loop', '1', '-i', state.imageFile!.path]);
        args.addAll(['-i', state.audioFile!.path]);
        
        // Use audio duration for video length
        if (audioDuration != null && audioDuration > 0) {
          args.addAll(['-t', audioDuration.toStringAsFixed(3)]);
          logBuffer.writeln('Setting video duration to match audio: ${audioDuration.toStringAsFixed(2)}s');
        }
        
        // Scale image to common resolutions if needed
        args.addAll([
          '-vf', 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2',
          '-r', '30', // Set frame rate
        ]);
      }

      // Common video codec options
      args.addAll([
        '-c:v', state.options.videoCodec,
        '-b:v', '${state.options.videoBitrateKbps}k',
        '-c:a', 'aac',
        '-b:a', '${state.options.audioBitrateKbps}k',
        '-pix_fmt', 'yuv420p', // Ensure compatibility
        '-shortest', // Ensure output ends when shortest stream ends
        outputFile.path,
      ]);

      logBuffer.writeln('FFmpeg command: ffmpeg ${args.join(' ')}');

      // Execute FFmpeg
      final totalSeconds = audioDuration ?? 0;
      
      final proc = await _ffmpegHelper.startFFmpeg(args);
      
      double lastProgress = -1;
      
      proc.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        logBuffer.writeln(line);
        
        // Parse progress
        if (totalSeconds > 0) {
          final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(line);
          if (timeMatch != null) {
            final h = double.parse(timeMatch.group(1)!);
            final m = double.parse(timeMatch.group(2)!);
            final s = double.parse(timeMatch.group(3)!);
            final currentSecs = h * 3600 + m * 60 + s;
            final progress = (currentSecs / totalSeconds).clamp(0.0, 1.0);
            
            if ((progress * 100).floor() != (lastProgress * 100).floor()) {
              lastProgress = progress;
              emit(state.copyWith(progress: progress));
            }
          }
        }
      });

      final exitCode = await proc.exitCode;

      if (exitCode == 0 && await outputFile.exists()) {
        emit(state.copyWith(
          isProcessing: false,
          progress: 1.0,
          output: outputFile,
          log: '✅ Merge completed successfully!\n📁 ${outputFile.path}\n${logBuffer.toString()}${state.log}',
        ));
      } else {
        emit(state.copyWith(
          isProcessing: false,
          error: 'FFmpeg exited with code $exitCode',
          log: '${logBuffer.toString()}${state.log}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isProcessing: false,
        error: 'Merge failed: $e',
      ));
    }
  }

  Future<double?> _getDuration(String filePath) async {
    try {
      final result = await _ffmpegHelper.runFFmpeg(['-i', filePath]);
      final output = result.stderr.toString();
      final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.?\d*)').firstMatch(output);
      if (match != null) {
        final h = double.parse(match.group(1)!);
        final m = double.parse(match.group(2)!);
        final s = double.parse(match.group(3)!);
        return h * 3600 + m * 60 + s;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _onReveal(RevealInFinderRequested e, Emitter<MergeState> emit) async {
    if (state.output != null) {
      final path = state.output!.path;
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      }
    }
  }

  void _onReset(ResetRequested e, Emitter<MergeState> emit) {
    emit(const MergeState());
    _hydrateOutputDir();
  }
}