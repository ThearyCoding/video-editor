import 'dart:async';
import 'dart:io';
import 'package:ffmepg_compress_video/features/shared/service/ffmpeg_process_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gif_event.dart';
import 'gif_state.dart';

const _kGifOutputDirKey = 'gif_output_dir';

class GifBloc extends Bloc<GifEvent, GifState> {
  final ImagePicker _picker = ImagePicker();
  final FfmpegProcessService _service = FfmpegProcessService();

  GifBloc() : super(const GifState()) {
    on<GifPickVideoRequested>(_onPickVideo);
    on<GifPickOutputDirRequested>(_onPickOutputDir);
    on<GifOptionsChanged>(_onOptionsChanged);
    on<GifConvertRequested>(_onConvert);
    on<GifResetRequested>(_onReset);
    _hydrateOutputDir();
  }

  Future<void> _hydrateOutputDir() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kGifOutputDirKey);
    if (saved != null && saved.isNotEmpty) {
      add(GifOptionsChanged(state.options.copyWith(outputDirPath: saved)));
    }
  }

  Future<void> _persistOutputDir(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kGifOutputDirKey, path);
  }

  Future<void> _onPickVideo(GifPickVideoRequested e, Emitter<GifState> emit) async {
    final XFile? xf = await _picker.pickVideo(source: ImageSource.gallery);
    if (xf == null) return;
    emit(state.copyWith(input: File(xf.path), output: null, progress: 0, log: 'Selected: ${xf.path}\n', error: null));
  }

  Future<void> _onPickOutputDir(GifPickOutputDirRequested e, Emitter<GifState> emit) async {
    final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose output folder (GIF)');
    if (path == null) return;
    await _persistOutputDir(path);
    emit(state.copyWith(outputDirPath: path));
  }

  void _onOptionsChanged(GifOptionsChanged e, Emitter<GifState> emit) {
    emit(state.copyWith(options: e.options));
  }

  Future<void> _onConvert(GifConvertRequested e, Emitter<GifState> emit) async {
    final input = state.input;
    if (input == null) return;

    emit(state.copyWith(isProcessing: true, progress: 0.0, error: null, output: null, log: state.log + 'Converting to GIF...\n'));

    final total = await _service.probeDurationSeconds(input);
    final out = await _service.buildOutputFile(input: input, directory: state.outputDirPath, suffix: 'gif', newExtension: 'gif');

    // filter chain: fps + optional scale + speed (setpts)
    final filters = <String>[];
    filters.add('fps=${state.options.fps}');
    final scale = _service.scaleFilter(width: state.options.width, height: state.options.height);
    if (scale.isNotEmpty) filters.add(scale);
    if (state.options.speedPercent != 100) {
      // >100 faster, <100 slower; setpts = 100/speed
      final factor = 100 / state.options.speedPercent;
      filters.add('setpts=${factor}*PTS');
    }
    final vf = filters.join(',');

    final args = <String>[
      '-y',
      '-i', input.path,
      '-vf', vf,
      '-loop', state.options.loop.toString(),
      '-f', 'gif',
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

    final combined = state.log + buf.toString() + '\n';
    if (res.exitCode == 0 && res.output != null) {
      emit(state.copyWith(isProcessing: false, progress: 1.0, output: res.output, log: combined + '✅ GIF created: ${res.output!.path}\n'));
    } else {
      emit(state.copyWith(isProcessing: false, log: combined, error: res.error ?? 'Unknown error'));
    }
  }

  void _onReset(GifResetRequested e, Emitter<GifState> emit) {
    emit(const GifState());
    _hydrateOutputDir();
  }
}
