import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/compressor/compression_options.dart';

abstract class MediaCompressEvent extends Equatable {
  const MediaCompressEvent();
  @override
  List<Object?> get props => [];
}

class PickVideoRequested extends MediaCompressEvent {
  const PickVideoRequested();
}

class PickImageRequested extends MediaCompressEvent {
  const PickImageRequested();
}

class PickOutputDirRequested extends MediaCompressEvent {
  const PickOutputDirRequested();
}

class CompressRequested extends MediaCompressEvent {
  const CompressRequested();
}

class OptionsChanged extends MediaCompressEvent {
  final CompressionOptions options;
  const OptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class ResetRequested extends MediaCompressEvent {
  const ResetRequested();
}

class MediaTypeChanged extends MediaCompressEvent {
  final MediaType mediaType;
  const MediaTypeChanged(this.mediaType);
  @override
  List<Object?> get props => [mediaType];
}