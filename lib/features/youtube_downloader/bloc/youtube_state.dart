import 'dart:io';
import 'package:equatable/equatable.dart';
import '../youtube_options.dart';

class YoutubeState extends Equatable {
  final String? url;
  final String? videoTitle;
  final String? videoAuthor;
  final String? videoDuration;
  final String? thumbnailUrl;
  final File? output;
  final String? outputDirPath;
  final YoutubeOptions options;
  final String log;
  final String? error;
  final bool isValidating;
  final bool isProcessing;
  final double progress;

  const YoutubeState({
    this.url,
    this.videoTitle,
    this.videoAuthor,
    this.videoDuration,
    this.thumbnailUrl,
    this.output,
    this.outputDirPath,
    this.options = const YoutubeOptions(),
    this.log = '',
    this.error,
    this.isValidating = false,
    this.isProcessing = false,
    this.progress = 0.0,
  });

  YoutubeState copyWith({
    String? url,
    String? videoTitle,
    String? videoAuthor,
    String? videoDuration,
    String? thumbnailUrl,
    File? output,
    String? outputDirPath,
    YoutubeOptions? options,
    String? log,
    String? error,
    bool? isValidating,
    bool? isProcessing,
    double? progress,
  }) {
    return YoutubeState(
      url: url ?? this.url,
      videoTitle: videoTitle ?? this.videoTitle,
      videoAuthor: videoAuthor ?? this.videoAuthor,
      videoDuration: videoDuration ?? this.videoDuration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      output: output ?? this.output,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      options: options ?? this.options,
      log: log ?? this.log,
      error: error,
      isValidating: isValidating ?? this.isValidating,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        url,
        videoTitle,
        videoAuthor,
        videoDuration,
        thumbnailUrl,
        output?.path,
        outputDirPath,
        options,
        log,
        error,
        isValidating,
        isProcessing,
        progress,
      ];
}