import 'package:equatable/equatable.dart';

enum MediaType { video, image }

class CompressionOptions extends Equatable {
  final MediaType mediaType;
  
  // Video options
  final String vCodec;   // 'libx264' or 'libx265'
  final int crf;         // 18..28 (smaller = higher)
  final String preset;   // ultrafast..veryslow
  
  // Image options
  final int imageQuality; // 0-100 (higher = better quality)
  final String imageFormat; // 'jpg', 'png', 'webp'
  
  // Common options
  final int? width;      // optional resize
  final int? height;     // optional resize
  final int audioBitrateK;
  final String? outputDirPath;

  const CompressionOptions({
    this.mediaType = MediaType.video,
    this.vCodec = 'libx264',
    this.crf = 24,
    this.preset = 'fast',
    this.imageQuality = 85,
    this.imageFormat = 'jpg',
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
      width: width ?? this.width,
      height: height ?? this.height,
      audioBitrateK: audioBitrateK ?? this.audioBitrateK,
      outputDirPath: outputDirPath ?? this.outputDirPath,
    );
  }

  @override
  List<Object?> get props => [
    mediaType, vCodec, crf, preset, imageQuality, 
    imageFormat, width, height, audioBitrateK, outputDirPath
  ];
}