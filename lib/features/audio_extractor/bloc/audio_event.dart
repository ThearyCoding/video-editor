import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/audio_extractor/audio_options.dart';

abstract class AudioEvent extends Equatable {
  const AudioEvent();
  @override
  List<Object?> get props => [];
}

class AudioPickVideoRequested extends AudioEvent {
  const AudioPickVideoRequested();
}

class AudioPickOutputDirRequested extends AudioEvent {
  const AudioPickOutputDirRequested();
}

class AudioOptionsChanged extends AudioEvent {
  final AudioOptions options;
  const AudioOptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class AudioExtractRequested extends AudioEvent {
  const AudioExtractRequested();
}

class AudioResetRequested extends AudioEvent {
  const AudioResetRequested();
}
