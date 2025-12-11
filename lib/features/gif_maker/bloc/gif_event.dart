import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/gif_maker/gif_options.dart';

abstract class GifEvent extends Equatable {
  const GifEvent();
  @override
  List<Object?> get props => [];
}

class GifPickVideoRequested extends GifEvent {
  const GifPickVideoRequested();
}

class GifPickOutputDirRequested extends GifEvent {
  const GifPickOutputDirRequested();
}

class GifOptionsChanged extends GifEvent {
  final GifOptions options;
  const GifOptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class GifConvertRequested extends GifEvent {
  const GifConvertRequested();
}

class GifResetRequested extends GifEvent {
  const GifResetRequested();
}
