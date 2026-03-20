import 'package:equatable/equatable.dart';

enum AudioFormat {
  mp3,
  aac,
  ogg,
  m4a,
  wav,
}

enum AudioQuality {
  veryLow,  // 64kbps
  low,      // 96kbps
  medium,   // 128kbps
  high,     // 192kbps
  veryHigh, // 256kbps
  extreme,  // 320kbps
}

extension AudioQualityExtension on AudioQuality {
  int get bitrate {
    switch (this) {
      case AudioQuality.veryLow:
        return 64;
      case AudioQuality.low:
        return 96;
      case AudioQuality.medium:
        return 128;
      case AudioQuality.high:
        return 192;
      case AudioQuality.veryHigh:
        return 256;
      case AudioQuality.extreme:
        return 320;
    }
  }
  
  String get label {
    switch (this) {
      case AudioQuality.veryLow:
        return '64 kbps (Very Low)';
      case AudioQuality.low:
        return '96 kbps (Low)';
      case AudioQuality.medium:
        return '128 kbps (Medium)';
      case AudioQuality.high:
        return '192 kbps (High)';
      case AudioQuality.veryHigh:
        return '256 kbps (Very High)';
      case AudioQuality.extreme:
        return '320 kbps (Extreme)';
    }
  }
}

enum ChannelMode {
  mono,
  stereo,
  jointStereo,
  dualChannel,
}

extension ChannelModeExtension on ChannelMode {
  String get ffmpegArg {
    switch (this) {
      case ChannelMode.mono:
        return 'mono';
      case ChannelMode.stereo:
        return 'stereo';
      case ChannelMode.jointStereo:
        return 'joint_stereo';
      case ChannelMode.dualChannel:
        return 'dual_mono';
    }
  }
  
  String get label {
    switch (this) {
      case ChannelMode.mono:
        return 'Mono';
      case ChannelMode.stereo:
        return 'Stereo';
      case ChannelMode.jointStereo:
        return 'Joint Stereo';
      case ChannelMode.dualChannel:
        return 'Dual Channel';
    }
  }
}
class AudioOptions extends Equatable {
  final AudioFormat format;
  final AudioQuality quality;
  final int? sampleRate;
  final ChannelMode channelMode;
  final bool preserveMetadata;
  final bool preserveAlbumArt;
  final bool removeAlbumArt; // Add this - opposite of preserveAlbumArt
  final bool normalizeVolume;
  final double? volumeTarget;
  final bool removeSilence;
  final double? silenceThreshold;
  final bool fadeInOut;
  final double? fadeDuration;
  final bool trimSilence;
  final double? startTime;
  final double? endTime;

  const AudioOptions({
    this.format = AudioFormat.mp3,
    this.quality = AudioQuality.medium,
    this.sampleRate,
    this.channelMode = ChannelMode.stereo,
    this.preserveMetadata = true,
    this.preserveAlbumArt = true,
    this.removeAlbumArt = false, // Add with default false
    this.normalizeVolume = false,
    this.volumeTarget,
    this.removeSilence = false,
    this.silenceThreshold,
    this.fadeInOut = false,
    this.fadeDuration,
    this.trimSilence = false,
    this.startTime,
    this.endTime,
  });

  AudioOptions copyWith({
    AudioFormat? format,
    AudioQuality? quality,
    int? sampleRate,
    ChannelMode? channelMode,
    bool? preserveMetadata,
    bool? preserveAlbumArt,
    bool? removeAlbumArt,
    bool? normalizeVolume,
    double? volumeTarget,
    bool? removeSilence,
    double? silenceThreshold,
    bool? fadeInOut,
    double? fadeDuration,
    bool? trimSilence,
    double? startTime,
    double? endTime,
  }) {
    return AudioOptions(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      sampleRate: sampleRate ?? this.sampleRate,
      channelMode: channelMode ?? this.channelMode,
      preserveMetadata: preserveMetadata ?? this.preserveMetadata,
      preserveAlbumArt: preserveAlbumArt ?? this.preserveAlbumArt,
      removeAlbumArt: removeAlbumArt ?? this.removeAlbumArt,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      volumeTarget: volumeTarget ?? this.volumeTarget,
      removeSilence: removeSilence ?? this.removeSilence,
      silenceThreshold: silenceThreshold ?? this.silenceThreshold,
      fadeInOut: fadeInOut ?? this.fadeInOut,
      fadeDuration: fadeDuration ?? this.fadeDuration,
      trimSilence: trimSilence ?? this.trimSilence,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [
        format,
        quality,
        sampleRate,
        channelMode,
        preserveMetadata,
        preserveAlbumArt,
        removeAlbumArt,
        normalizeVolume,
        volumeTarget,
        removeSilence,
        silenceThreshold,
        fadeInOut,
        fadeDuration,
        trimSilence,
        startTime,
        endTime,
      ];
}