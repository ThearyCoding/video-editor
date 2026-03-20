import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:ffmepg_compress_video/features/audio_compressor/audio_compressor.dart';

abstract class AudioCompressorEvent extends Equatable {
  const AudioCompressorEvent();
  @override
  List<Object?> get props => [];
}

class PickAudioRequested extends AudioCompressorEvent {
  const PickAudioRequested();
}

class PickOutputDirRequested extends AudioCompressorEvent {
  const PickOutputDirRequested();
}

class AudioOptionsChanged extends AudioCompressorEvent {
  final AudioOptions options;
  const AudioOptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class CompressAudioRequested extends AudioCompressorEvent {
  const CompressAudioRequested();
}

class PreviewAudioRequested extends AudioCompressorEvent {
  const PreviewAudioRequested();
}

class StopPreviewRequested extends AudioCompressorEvent {
  const StopPreviewRequested();
}

class RevealInFinderRequested extends AudioCompressorEvent {
  const RevealInFinderRequested();
}

class ResetRequested extends AudioCompressorEvent {
  const ResetRequested();
}