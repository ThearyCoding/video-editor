import 'package:equatable/equatable.dart';

enum DownloadFormat {
  video,
  audio,
}

class YoutubeOptions extends Equatable {
  final DownloadFormat format;
  final String? videoQuality; // e.g., '1080p', '720p', '480p', '360p'
  final String? audioBitrate; // e.g., '128kbps', '192kbps', '256kbps'
  final bool downloadPlaylist;

  const YoutubeOptions({
    this.format = DownloadFormat.video,
    this.videoQuality,
    this.audioBitrate,
    this.downloadPlaylist = false,
  });

  YoutubeOptions copyWith({
    DownloadFormat? format,
    String? videoQuality,
    String? audioBitrate,
    bool? downloadPlaylist,
  }) {
    return YoutubeOptions(
      format: format ?? this.format,
      videoQuality: videoQuality ?? this.videoQuality,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      downloadPlaylist: downloadPlaylist ?? this.downloadPlaylist,
    );
  }

  @override
  List<Object?> get props => [format, videoQuality, audioBitrate, downloadPlaylist];
}