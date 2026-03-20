import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/audio_compressor/audio_compressor.dart';

class AudioCompressorState extends Equatable {
  final File? inputFile;
  final File? outputFile;
  final String? outputDirPath;
  final AudioOptions options;
  final String log;
  final String? error;
  final bool isLoading;
  final bool isProcessing;
  final bool isPreviewing;
  final double progress;
  
  // Audio metadata
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final int? originalBitrate;
  final int? originalSampleRate;
  final String? originalFormat;
  final bool hasAlbumArt;
  final Uint8List? albumArtThumbnail;

  const AudioCompressorState({
    this.inputFile,
    this.outputFile,
    this.outputDirPath,
    this.options = const AudioOptions(),
    this.log = '',
    this.error,
    this.isLoading = false,
    this.isProcessing = false,
    this.isPreviewing = false,
    this.progress = 0.0,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.originalBitrate,
    this.originalSampleRate,
    this.originalFormat,
    this.hasAlbumArt = false,
    this.albumArtThumbnail,
  });

  AudioCompressorState copyWith({
    File? inputFile,
    File? outputFile,
    String? outputDirPath,
    AudioOptions? options,
    String? log,
    String? error,
    bool? isLoading,
    bool? isProcessing,
    bool? isPreviewing,
    double? progress,
    String? title,
    String? artist,
    String? album,
    int? duration,
    int? originalBitrate,
    int? originalSampleRate,
    String? originalFormat,
    bool? hasAlbumArt,
    Uint8List? albumArtThumbnail,
  }) {
    return AudioCompressorState(
      inputFile: inputFile ?? this.inputFile,
      outputFile: outputFile ?? this.outputFile,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      options: options ?? this.options,
      log: log ?? this.log,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      progress: progress ?? this.progress,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      originalBitrate: originalBitrate ?? this.originalBitrate,
      originalSampleRate: originalSampleRate ?? this.originalSampleRate,
      originalFormat: originalFormat ?? this.originalFormat,
      hasAlbumArt: hasAlbumArt ?? this.hasAlbumArt,
      albumArtThumbnail: albumArtThumbnail ?? this.albumArtThumbnail,
    );
  }

  @override
  List<Object?> get props => [
        inputFile?.path,
        outputFile?.path,
        outputDirPath,
        options,
        log,
        error,
        isLoading,
        isProcessing,
        isPreviewing,
        progress,
        title,
        artist,
        album,
        duration,
        originalBitrate,
        originalSampleRate,
        originalFormat,
        hasAlbumArt,
        albumArtThumbnail,
      ];
}