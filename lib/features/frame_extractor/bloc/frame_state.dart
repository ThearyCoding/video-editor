import 'dart:io';
import 'package:equatable/equatable.dart';
import '../models/frame_options.dart';

class FrameState extends Equatable {
  final File? input;
  final String? outputDirPath;
  final FrameOptions options;
  final bool isProcessing;
  final double progress;
  final String log;
  final String? error;

  const FrameState({
    this.input,
    this.outputDirPath,
    this.options = const FrameOptions(),
    this.isProcessing = false,
    this.progress = 0,
    this.log = '',
    this.error,
  });

  FrameState copyWith({
    File? input,
    String? outputDirPath,
    FrameOptions? options,
    bool? isProcessing,
    double? progress,
    String? log,
    String? error,
  }) => FrameState(
        input: input ?? this.input,
        outputDirPath: outputDirPath ?? this.outputDirPath,
        options: options ?? this.options,
        isProcessing: isProcessing ?? this.isProcessing,
        progress: progress ?? this.progress,
        log: log ?? this.log,
        error: error,
      );

  @override
  List<Object?> get props => [input?.path, outputDirPath, options, isProcessing, progress, log, error];
}
