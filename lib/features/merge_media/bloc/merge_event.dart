import 'dart:io';
import 'package:equatable/equatable.dart';
import '../merge_options.dart';

abstract class MergeEvent extends Equatable {
  const MergeEvent();
  @override
  List<Object?> get props => [];
}

class PickVideoRequested extends MergeEvent {
  const PickVideoRequested();
}

class PickImageRequested extends MergeEvent {
  const PickImageRequested();
}

class PickAudioRequested extends MergeEvent {
  const PickAudioRequested();
}

class PickOutputDirRequested extends MergeEvent {
  const PickOutputDirRequested();
}

class MergeOptionsChanged extends MergeEvent {
  final MergeOptions options;
  const MergeOptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class MergeTypeChanged extends MergeEvent {
  final MergeType mergeType;
  const MergeTypeChanged(this.mergeType);
  @override
  List<Object?> get props => [mergeType];
}

class MergeRequested extends MergeEvent {
  const MergeRequested();
}

class RevealInFinderRequested extends MergeEvent {
  const RevealInFinderRequested();
}

class ResetRequested extends MergeEvent {
  const ResetRequested();
}

enum MergeType {
  videoAudio,  // Combine video + audio
  imageAudio,  // Combine image + audio
}