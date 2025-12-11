import 'dart:async';
import 'dart:io';
import 'package:ffmepg_compress_video/features/shared/service/ffmpeg_process_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_event.dart';
import 'audio_state.dart';

const _kAudioOutputDirKey = 'audio_output_dir';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final ImagePicker _picker = ImagePicker();
  final FfmpegProcessService _service = FfmpegProcessService();

  AudioBloc() : super(const AudioState()) {
    on<AudioPickVideoRequested>(_onPickVideo);
    on<AudioPickOutputDirRequested>(_onPickOutputDir);
    on<AudioOptionsChanged>(_onOptionsChanged);
    on<AudioExtractRequested>(_onExtract);
    on<AudioResetRequested>(_onReset);
    _initOutputDir();
  }

  Future<void> _initOutputDir() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kAudioOutputDirKey);
    if (saved != null && saved.isNotEmpty) {
      add(AudioOptionsChanged(state.options.copyWith(outputDirPath: saved)));
    }
  }

  Future<void> _persistOutputDir(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAudioOutputDirKey, path);
  }

  Future<void> _onPickVideo(AudioPickVideoRequested e, Emitter<AudioState> emit) async {
    final XFile? xf = await _picker.pickVideo(source: ImageSource.gallery);
    if (xf == null) return;
    emit(state.copyWith(input: File(xf.path), output: null, progress: 0, log: 'Selected: ${xf.path}\n', error: null));
  }

  Future<void> _onPickOutputDir(AudioPickOutputDirRequested e, Emitter<AudioState> emit) async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose output folder (MP3)');
    if (path == null) return;
    await _persistOutputDir(path);
    emit(state.copyWith(outputDirPath: path));
  }

  void _onOptionsChanged(AudioOptionsChanged e, Emitter<AudioState> emit) {
    emit(state.copyWith(options: e.options));
  }

  Future<void> _onExtract(AudioExtractRequested e, Emitter<AudioState> emit) async {
    final input = state.input;
    if (input == null) return;

    emit(state.copyWith(isProcessing: true, progress: 0.0, error: null, output: null, log: state.log + 'Extracting MP3...\n'));

    final total = await _service.probeDurationSeconds(input);
    final out = await _service.buildOutputFile(input: input, directory: state.outputDirPath, suffix: 'audio', newExtension: 'mp3');

    final args = <String>[
      '-y',
      '-i', input.path,
      '-vn',                // no video
      '-acodec', 'libmp3lame',
      '-b:a', '${state.options.bitrateK}k',
      out.path,
    ];

    final buf = StringBuffer();
    final res = await _service.runWithProgress(
      args: args,
      expectedOutput: out,
      totalSeconds: total,
      onLog: (l) => buf.writeln(l),
      onProgress: (p) => emit(state.copyWith(progress: p)),
    );

    final combined = '${state.log}$buf\n';
    if (res.exitCode == 0 && res.output != null) {
      emit(state.copyWith(isProcessing: false, progress: 1.0, output: res.output, log: combined + '✅ MP3 saved: ${res.output!.path}\n'));
    } else {
      emit(state.copyWith(isProcessing: false, log: combined, error: res.error ?? 'Unknown error'));
    }
  }

  void _onReset(AudioResetRequested e, Emitter<AudioState> emit) {
    emit(const AudioState());
    _initOutputDir();
  }
}
