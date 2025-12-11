import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/service/ffmpeg_process_service.dart';
import 'frame_event.dart';
import 'frame_state.dart';

const _kFramesOutputDirKey = 'frames_output_dir';

class FrameBloc extends Bloc<FrameEvent, FrameState> {
  final ImagePicker _picker = ImagePicker();
  final FfmpegProcessService _service = FfmpegProcessService();

  FrameBloc() : super(const FrameState()) {
    on<FramePickVideoRequested>(_onPickVideo);
    on<FramePickOutputDirRequested>(_onPickDir);
    on<FrameOptionsChanged>(_onOptions);
    on<FrameExtractRequested>(_onExtract);
    on<FrameResetRequested>(_onReset);
    _hydrate();
  }

  Future<void> _hydrate() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kFramesOutputDirKey);
    if (saved != null && saved.isNotEmpty) emit(state.copyWith(outputDirPath: saved));
  }

  Future<void> _persistDir(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kFramesOutputDirKey, path);
  }

  Future<void> _onPickVideo(FramePickVideoRequested e, Emitter<FrameState> emit) async {
    final XFile? xf = await _picker.pickVideo(source: ImageSource.gallery);
    if (xf == null) return;
    emit(state.copyWith(input: File(xf.path), progress: 0, log: 'Selected: ${xf.path}\n', error: null));
  }

  Future<void> _onPickDir(FramePickOutputDirRequested e, Emitter<FrameState> emit) async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose folder for frames');
    if (path == null) return;
    await _persistDir(path);
    emit(state.copyWith(outputDirPath: path));
  }

  void _onOptions(FrameOptionsChanged e, Emitter<FrameState> emit) => emit(state.copyWith(options: e.options));

  Future<void> _onExtract(FrameExtractRequested e, Emitter<FrameState> emit) async {
    final input = state.input; if (input == null) return;

    emit(state.copyWith(isProcessing: true, progress: 0, error: null, log: state.log + 'Extracting frames...\n'));

    final total = await _service.probeDurationSeconds(input);
    final outDir = await _service.ensureOutputDir(directory: state.outputDirPath, fallbackName: 'frames');
    final pattern = _service.patternIn(outDir, state.options.format.toLowerCase());

    // fps filter: every N seconds => fps=1/N
    final fps = state.options.everySec <= 0 ? 1 : (1 / state.options.everySec);
    final filters = <String>['fps=$fps'];
    final scale = _service.scaleFilter(width: state.options.width, height: state.options.height);
    if (scale.isNotEmpty) filters.add(scale);

    final args = <String>[
      '-y', '-i', input.path, '-vf', filters.join(','), pattern,
    ];

    final buf = StringBuffer();
    final res = await _service.runLoose(
      args: args,
      outputDir: outDir,
      totalSeconds: total,
      onLog: (l) => buf.writeln(l),
      onProgress: (p) => emit(state.copyWith(progress: p)),
    );

    final combined = state.log + buf.toString() + '\n';
    if (res.exitCode == 0) {
      emit(state.copyWith(isProcessing: false, progress: 1.0, log: combined + '✅ Frames saved to: $outDir\n'));
    } else {
      emit(state.copyWith(isProcessing: false, log: combined, error: res.error ?? 'Unknown error'));
    }
  }

  void _onReset(FrameResetRequested e, Emitter<FrameState> emit) {
    emit(const FrameState());
    _hydrate();
  }
}
