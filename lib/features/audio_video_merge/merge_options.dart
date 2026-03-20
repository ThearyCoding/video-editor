import 'package:equatable/equatable.dart';

class MergeOptions extends Equatable {
  final String videoCodec;
  final int videoBitrateKbps;
  final int audioBitrateKbps;
  final bool useShortestAudio; // If true, trim to shortest duration

  const MergeOptions({
    this.videoCodec = 'libx264',
    this.videoBitrateKbps = 2000,
    this.audioBitrateKbps = 192,
    this.useShortestAudio = true,
  });

  MergeOptions copyWith({
    String? videoCodec,
    int? videoBitrateKbps,
    int? audioBitrateKbps,
    bool? useShortestAudio,
  }) {
    return MergeOptions(
      videoCodec: videoCodec ?? this.videoCodec,
      videoBitrateKbps: videoBitrateKbps ?? this.videoBitrateKbps,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      useShortestAudio: useShortestAudio ?? this.useShortestAudio,
    );
  }

  @override
  List<Object?> get props => [
        videoCodec,
        videoBitrateKbps,
        audioBitrateKbps,
        useShortestAudio,
      ];
}