import 'package:equatable/equatable.dart';

class CompressionOptions extends Equatable {
  final String vCodec;   // 'libx264' or 'libx265'
  final int crf;         // 18..28 (smaller = higher)
  final String preset;   // ultrafast..veryslow
  final int? width;      // optional resize
  final int? height;     // optional resize
  final int audioBitrateK;
    final String? outputDirPath;

  const CompressionOptions({
    this.vCodec = 'libx264',
    this.crf = 24,
    this.preset = 'fast',
    this.width,
        this.outputDirPath,
    this.height,
    this.audioBitrateK = 128,
  });

  CompressionOptions copyWith({
    String? vCodec,
    int? crf,
    String? preset,
    int? width,
    int? height,
    int? audioBitrateK,
     String? outputDirPath,
  }) {
    return CompressionOptions(
      vCodec: vCodec ?? this.vCodec,
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      width: width ?? this.width,
      height: height ?? this.height,
      audioBitrateK: audioBitrateK ?? this.audioBitrateK,
            outputDirPath: outputDirPath ?? this.outputDirPath,
    );
  }

  @override
  List<Object?> get props => [vCodec, crf, preset, width, height, audioBitrateK];
}
