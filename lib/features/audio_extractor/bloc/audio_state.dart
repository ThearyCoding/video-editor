import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/audio_extractor/audio_options.dart';

class AudioState extends Equatable {
  final File? input;
  final File? output;
  final String? outputDirPath;
  final AudioOptions options;
  final String log;
  final String? error;
  final bool isProcessing;
  final double progress;

  const AudioState({
    this.input,
    this.output,
    this.outputDirPath,
    this.options = const AudioOptions(),
    this.log = '',
    this.error,
    this.isProcessing = false,
    this.progress = 0.0,
  });

  AudioState copyWith({
    File? input,
    File? output,
    String? outputDirPath,
    AudioOptions? options,
    String? log,
    String? error,
    bool? isProcessing,
    double? progress,
  }) => AudioState(
        input: input ?? this.input,
        output: output ?? this.output,
        outputDirPath: outputDirPath ?? this.outputDirPath,
        options: options ?? this.options,
        log: log ?? this.log,
        error: error,
        isProcessing: isProcessing ?? this.isProcessing,
        progress: progress ?? this.progress,
      );

  @override
  List<Object?> get props => [input?.path, output?.path, outputDirPath, options, log, error, isProcessing, progress];
}
