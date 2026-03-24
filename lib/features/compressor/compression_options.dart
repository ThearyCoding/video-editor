import 'package:equatable/equatable.dart';

enum MediaType { video, image }

class CompressionOptions extends Equatable {
  final MediaType mediaType;
  
  // Video options
  final String vCodec;
  final int crf;
  final String preset;
  
  // Image options
  final int imageQuality;
  final String imageFormat;
  final int? targetSizeKB;
  
  // Common options
  final int? width;
  final int? height;
  final int audioBitrateK;
  final String? outputDirPath;

  const CompressionOptions({
    this.mediaType = MediaType.video,
    this.vCodec = 'libx264',
    this.crf = 24,
    this.preset = 'fast',
    this.imageQuality = 85,
    this.imageFormat = 'jpg',
    this.targetSizeKB,
    this.width,
    this.outputDirPath,
    this.height,
    this.audioBitrateK = 128,
  });

  CompressionOptions copyWith({
    MediaType? mediaType,
    String? vCodec,
    int? crf,
    String? preset,
    int? imageQuality,
    String? imageFormat,
    int? targetSizeKB,
    int? width,
    int? height,
    int? audioBitrateK,
    String? outputDirPath,
  }) {
    return CompressionOptions(
      mediaType: mediaType ?? this.mediaType,
      vCodec: vCodec ?? this.vCodec,
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      imageQuality: imageQuality ?? this.imageQuality,
      imageFormat: imageFormat ?? this.imageFormat,
      targetSizeKB: targetSizeKB ?? this.targetSizeKB,
      width: width ?? this.width,
      height: height ?? this.height,
      audioBitrateK: audioBitrateK ?? this.audioBitrateK,
      outputDirPath: outputDirPath ?? this.outputDirPath,
    );
  }

  @override
  List<Object?> get props => [
    mediaType, vCodec, crf, preset, imageQuality, 
    imageFormat, targetSizeKB, width, height, audioBitrateK, outputDirPath
  ];
}