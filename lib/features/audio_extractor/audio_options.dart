import 'package:equatable/equatable.dart';

class AudioOptions extends Equatable {
  final int bitrateK;
  const AudioOptions({this.bitrateK = 192});
  AudioOptions copyWith({
    int? bitrateK,
    String? outputDirPath,
  }) {
    return AudioOptions(
      bitrateK: bitrateK ?? this.bitrateK,
    );
  }

  @override
  List<Object?> get props => [bitrateK];
}
