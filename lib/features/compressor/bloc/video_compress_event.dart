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

class PickImageRequested extends VideoCompressEvent {
  const PickImageRequested();
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

class MediaTypeChanged extends VideoCompressEvent {
  final MediaType mediaType;
  const MediaTypeChanged(this.mediaType);
  @override
  List<Object?> get props => [mediaType];
}