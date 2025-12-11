import 'package:equatable/equatable.dart';
import '../models/frame_options.dart';

abstract class FrameEvent extends Equatable { const FrameEvent(); @override List<Object?> get props => []; }
class FramePickVideoRequested extends FrameEvent { const FramePickVideoRequested(); }
class FramePickOutputDirRequested extends FrameEvent { const FramePickOutputDirRequested(); }
class FrameOptionsChanged extends FrameEvent { final FrameOptions options; const FrameOptionsChanged(this.options); @override List<Object?> get props => [options]; }
class FrameExtractRequested extends FrameEvent { const FrameExtractRequested(); }
class FrameResetRequested extends FrameEvent { const FrameResetRequested(); }
