import 'package:equatable/equatable.dart';
import '../youtube_options.dart';

abstract class YoutubeEvent extends Equatable {
  const YoutubeEvent();
  @override
  List<Object?> get props => [];
}

class UrlChanged extends YoutubeEvent {
  final String url;
  const UrlChanged(this.url);
  @override
  List<Object?> get props => [url];
}

class ValidateUrlRequested extends YoutubeEvent {
  const ValidateUrlRequested();
}

class PickOutputDirRequested extends YoutubeEvent {
  const PickOutputDirRequested();
}

class OptionsChanged extends YoutubeEvent {
  final YoutubeOptions options;
  const OptionsChanged(this.options);
  @override
  List<Object?> get props => [options];
}

class DownloadRequested extends YoutubeEvent {
  const DownloadRequested();
}

class ResetRequested extends YoutubeEvent {
  const ResetRequested();
}

class RevealInFinderRequested extends YoutubeEvent {
  const RevealInFinderRequested();
}