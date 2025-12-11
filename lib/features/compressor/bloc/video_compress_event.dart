import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/compressor/compression_options.dart';

abstract class VideoCompressEvent extends Equatable {
  const VideoCompressEvent();
  @override
  List<Object?> get props => [];
}

class PickVideoRequested extends VideoCompressEvent {
  const PickVideoRequested();
}

class PickOutputDirRequested extends VideoCompressEvent {
  const PickOutputDirRequested();
}

class CompressRequested extends VideoCompressEvent {
  const CompressRequested();
}

class OptionsChanged extends VideoCompressEvent {
  final CompressionOptions options;
  const OptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class ResetRequested extends VideoCompressEvent {
  const ResetRequested();
}
