import 'dart:io';
import 'package:equatable/equatable.dart';
import '../merge_options.dart';
import 'merge_event.dart';

class MergeState extends Equatable {
  final File? videoFile;
  final File? imageFile;
  final File? audioFile;
  final File? output;
  final String? outputDirPath;
  final MergeOptions options;
  final MergeType mergeType;
  final String log;
  final String? error;
  final bool isProcessing;
  final double progress;

  const MergeState({
    this.videoFile,
    this.imageFile,
    this.audioFile,
    this.output,
    this.outputDirPath,
    this.options = const MergeOptions(),
    this.mergeType = MergeType.videoAudio,
    this.log = '',
    this.error,
    this.isProcessing = false,
    this.progress = 0.0,
  });

  MergeState copyWith({
    File? videoFile,
    File? imageFile,
    File? audioFile,
    File? output,
    String? outputDirPath,
    MergeOptions? options,
    MergeType? mergeType,
    String? log,
    String? error,
    bool? isProcessing,
    double? progress,
  }) {
    return MergeState(
      videoFile: videoFile ?? this.videoFile,
      imageFile: imageFile ?? this.imageFile,
      audioFile: audioFile ?? this.audioFile,
      output: output ?? this.output,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      options: options ?? this.options,
      mergeType: mergeType ?? this.mergeType,
      log: log ?? this.log,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        videoFile?.path,
        imageFile?.path,
        audioFile?.path,
        output?.path,
        outputDirPath,
        options,
        mergeType,
        log,
        error,
        isProcessing,
        progress,
      ];
}