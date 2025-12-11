import 'package:equatable/equatable.dart';

class FrameOptions extends Equatable {
  final int everySec;      // 1 = 1 frame/sec
  final String format;     // 'png' or 'jpg'
  final int? width;
  final int? height;

  const FrameOptions({
    this.everySec = 1,
    this.format = 'png',
    this.width,
    this.height,
  });

  @override
  List<Object?> get props => [everySec, format, width, height];
}
