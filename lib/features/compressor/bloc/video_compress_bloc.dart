import 'dart:async';
import 'dart:io';
import 'package:ffmepg_compress_video/features/compressor/compression_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/ffmpeg_process_service.dart';
import 'video_compress_event.dart';
import 'video_compress_state.dart';

const _kOutputDirKey = 'video_output_dir';

class VideoCompressBloc extends Bloc<VideoCompressEvent, VideoCompressState> {
  final ImagePicker _picker = ImagePicker();
  final FfmpegProcessService _service = FfmpegProcessService();

  VideoCompressBloc() : super(const VideoCompressState()) {
    on<PickVideoRequested>(_onPickVideo);
    on<PickImageRequested>(_onPickImage);
    on<PickOutputDirRequested>(_onPickOutputDir);
    on<CompressRequested>(_onCompress);
    on<OptionsChanged>(_onOptionsChanged);
    on<ResetRequested>(_onReset);
    on<MediaTypeChanged>(_onMediaTypeChanged);
    _hydrateOutputDir();
  }

  Future<void> _hydrateOutputDir() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_kOutputDirKey);
      if (saved != null && saved.isNotEmpty) {
        add(OptionsChanged(state.options.copyWith(outputDirPath: saved)));
      }
    } catch (_) {}
  }

  Future<void> _persistOutputDir(String path) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kOutputDirKey, path);
    } catch (_) {}
  }

  Future<void> _onPickVideo(PickVideoRequested e, Emitter<VideoCompressState> emit) async {
    final XFile? xf = await _picker.pickVideo(source: ImageSource.gallery);
    if (xf == null) return;
    emit(state.copyWith(
      input: File(xf.path),
      output: null,
      progress: 0.0,
      log: 'Selected video: ${xf.path}\n',
      error: null,
    ));
  }

  Future<void> _onPickImage(PickImageRequested e, Emitter<VideoCompressState> emit) async {
    final XFile? xf = await _picker.pickImage(source: ImageSource.gallery);
    if (xf == null) return;
    emit(state.copyWith(
      input: File(xf.path),
      output: null,
      progress: 0.0,
      log: 'Selected image: ${xf.path}\n',
      error: null,
    ));
  }

  Future<void> _onPickOutputDir(PickOutputDirRequested e, Emitter<VideoCompressState> emit) async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose output folder');
    if (path == null) return;
    await _persistOutputDir(path);
    emit(state.copyWith(outputDirPath: path));
  }

  Future<void> _onCompress(CompressRequested e, Emitter<VideoCompressState> emit) async {
    final input = state.input;
    if (input == null) return;

    final mediaTypeStr = state.options.mediaType == MediaType.video ? 'video' : 'image';
    emit(state.copyWith(
      isProcessing: true,
      progress: 0.0,
      log: '${state.log}Starting $mediaTypeStr compression...\n',
      error: null,
      output: null,
    ));

    final buf = StringBuffer();

    void onLog(String line) => buf.writeln(line);
    void onProgress(double p01) => emit(state.copyWith(progress: p01));

    final res = await _service.compress(
      input: input,
      options: state.options,
      outputDirectory: state.outputDirPath,
      onLog: onLog,
      onProgress: onProgress,
    );

    final combined = '${state.log}$buf\n';
    if (res.exitCode == 0 && res.output != null) {
      emit(state.copyWith(
        isProcessing: false,
        progress: 1.0,
        output: res.output,
        log: '${combined}Compression successful!\nOutput: ${res.output!.path}\n',
      ));
    } else {
      emit(state.copyWith(isProcessing: false, log: combined, error: res.error ?? 'Unknown error'));
    }
  }
  
  void _onOptionsChanged(OptionsChanged e, Emitter<VideoCompressState> emit) {
    emit(state.copyWith(options: e.options));
  }

  void _onReset(ResetRequested e, Emitter<VideoCompressState> emit) {
    emit(const VideoCompressState());
    _hydrateOutputDir();
  }

  void _onMediaTypeChanged(MediaTypeChanged e, Emitter<VideoCompressState> emit) {
    emit(state.copyWith(
      options: state.options.copyWith(mediaType: e.mediaType),
      input: null,
      output: null,
      log: '',
      error: null,
      progress: 0.0,
    ));
  }
}