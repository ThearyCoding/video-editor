import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/compressor/compression_options.dart';

class VideoCompressState extends Equatable {
  final File? input;
  final File? output;
  final bool isProcessing;
  final String log;
  final String? error;
  final CompressionOptions options;
  final String? outputDirPath;  // saved folder
  final double progress;        // 0..1

  const VideoCompressState({
    this.input,
    this.output,
    this.isProcessing = false,
    this.log = '',
    this.error,
    this.options = const CompressionOptions(),
    this.outputDirPath,
    this.progress = 0.0,
  });

  VideoCompressState copyWith({
    File? input,
    File? output,
    bool? isProcessing,
    String? log,
    String? error,
    CompressionOptions? options,
    String? outputDirPath,
    double? progress,
  }) {
    return VideoCompressState(
      input: input ?? this.input,
      output: output ?? this.output,
      isProcessing: isProcessing ?? this.isProcessing,
      log: log ?? this.log,
      error: error,
      options: options ?? this.options,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        input?.path,
        output?.path,
        isProcessing,
        log,
        error,
        options,
        outputDirPath,
        progress,
      ];
}
