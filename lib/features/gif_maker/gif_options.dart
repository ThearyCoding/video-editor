import 'package:equatable/equatable.dart';

class GifOptions extends Equatable {
  final int fps;          // e.g. 12
  final int? width;       // optional resize
  final int? height;      // optional resize
  final int loop;         // 0 = infinite
  final int speedPercent; // 100 normal (set via setpts)

  const GifOptions({
    this.fps = 12,
    this.width,
    this.height,
    this.loop = 0,
    this.speedPercent = 100,
  });
GifOptions copyWith({
    int? fps,
    int? width,
    int? height,
    int? speedPercent,
    int? loop,
    String? outputDirPath,
  }) {
    return GifOptions(
      fps: fps ?? this.fps,
      width: width ?? this.width,
      height: height ?? this.height,
      speedPercent: speedPercent ?? this.speedPercent,
      loop: loop ?? this.loop,
    );
  }

  @override
  List<Object?> get props => [fps, width, height, loop, speedPercent];
}
