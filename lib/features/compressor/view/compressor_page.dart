import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/video_compress_bloc.dart';
import '../bloc/video_compress_event.dart';
import '../bloc/video_compress_state.dart';
import '../compression_options.dart' as mymodel;

class CompressorPage extends StatelessWidget {
  const CompressorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoCompressBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Compressor')),
      body: BlocBuilder<VideoCompressBloc, VideoCompressState>(
        builder: (context, state) {
          final bloc = context.read<VideoCompressBloc>();
          final pct = (state.progress * 100).clamp(0, 100).round();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Type Selector
                SegmentedButton<mymodel.MediaType>(
                  segments: const [
                    ButtonSegment(value: mymodel.MediaType.video, label: Text('Video'), icon: Icon(Icons.videocam)),
                    ButtonSegment(value: mymodel.MediaType.image, label: Text('Image'), icon: Icon(Icons.image)),
                  ],
                  selected: {state.options.mediaType},
                  onSelectionChanged: (Set<mymodel.MediaType> selection) {
                    bloc.add(MediaTypeChanged(selection.first));
                  },
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => bloc.add(
                        state.options.mediaType == mymodel.MediaType.video 
                          ? const PickVideoRequested() 
                          : const PickImageRequested()
                      ),
                      icon: Icon(state.options.mediaType == mymodel.MediaType.video ? Icons.video_library : Icons.image),
                      label: Text(state.options.mediaType == mymodel.MediaType.video ? 'Select Video' : 'Select Image'),
                    ),
                    FilledButton.icon(
                      onPressed: () => bloc.add(const PickOutputDirRequested()),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choose Output Folder'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isProcessing || state.input == null
                          ? null
                          : () => bloc.add(const CompressRequested()),
                      icon: state.isProcessing
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.compress),
                      label: Text(state.isProcessing ? 'Compressing…' : 'Compress'),
                    ),
                    TextButton.icon(
                      onPressed: () => bloc.add(const ResetRequested()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.outputDirPath != null)
                  Text('Output folder: ${state.outputDirPath}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (state.input != null)
                  Text('Input: ${state.input!.path}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (state.output != null)
                  Text('Output: ${state.output!.path}', style: const TextStyle(fontWeight: FontWeight.w600)),

                const SizedBox(height: 16),
                if (state.isProcessing) ...[
                  LinearProgressIndicator(value: state.progress > 0 ? state.progress : null),
                  const SizedBox(height: 8),
                  Text('Progress: $pct%'),
                ],

                const SizedBox(height: 16),
                _OptionsPanel(options: state.options),

                const SizedBox(height: 16),
                const Text('Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        state.log + (state.error != null ? '\n❌ ${state.error}' : ''),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OptionsPanel extends StatefulWidget {
  final mymodel.CompressionOptions options;
  const _OptionsPanel({required this.options});

  @override
  State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  late TextEditingController _crf, _w, _h, _audio, _imageQuality;
  String _codec = 'libx264';
  String _preset = 'fast';
  String _imageFormat = 'jpg';

  @override
  void initState() {
    super.initState();
    _crf = TextEditingController(text: widget.options.crf.toString());
    _w = TextEditingController(text: widget.options.width?.toString() ?? '');
    _h = TextEditingController(text: widget.options.height?.toString() ?? '');
    _audio = TextEditingController(text: widget.options.audioBitrateK.toString());
    _imageQuality = TextEditingController(text: widget.options.imageQuality.toString());
    _codec = widget.options.vCodec;
    _preset = widget.options.preset;
    _imageFormat = widget.options.imageFormat;
  }

  void _apply() {
    final o = mymodel.CompressionOptions(
      mediaType: widget.options.mediaType,
      vCodec: _codec,
      crf: int.tryParse(_crf.text.trim()) ?? 24,
      preset: _preset,
      imageQuality: int.tryParse(_imageQuality.text.trim()) ?? 85,
      imageFormat: _imageFormat,
      width: _w.text.trim().isEmpty ? null : int.tryParse(_w.text.trim()),
      height: _h.text.trim().isEmpty ? null : int.tryParse(_h.text.trim()),
      audioBitrateK: int.tryParse(_audio.text.trim()) ?? 128,
    );
    
    final bloc = context.read<VideoCompressBloc>();
    bloc.add(OptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.mediaType == mymodel.MediaType.video) {
      return _buildVideoOptions();
    } else {
      return _buildImageOptions();
    }
  }

  Widget _buildVideoOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 90, child: TextField(controller: _crf, decoration: const InputDecoration(labelText: 'CRF 18–28'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        DropdownButton<String>(
          value: _codec,
          onChanged: (v) { if (v == null) return; setState(() => _codec = v); _apply(); },
          items: const [
            DropdownMenuItem(value: 'libx264', child: Text('H.264 (x264)')),
            DropdownMenuItem(value: 'libx265', child: Text('H.265 (x265)')),
          ],
        ),
        DropdownButton<String>(
          value: _preset,
          onChanged: (v) { if (v == null) return; setState(() => _preset = v); _apply(); },
          items: const [
            DropdownMenuItem(value: 'ultrafast', child: Text('ultrafast')),
            DropdownMenuItem(value: 'superfast', child: Text('superfast')),
            DropdownMenuItem(value: 'veryfast', child: Text('veryfast')),
            DropdownMenuItem(value: 'faster', child: Text('faster')),
            DropdownMenuItem(value: 'fast', child: Text('fast')),
            DropdownMenuItem(value: 'medium', child: Text('medium')),
            DropdownMenuItem(value: 'slow', child: Text('slow')),
            DropdownMenuItem(value: 'slower', child: Text('slower')),
            DropdownMenuItem(value: 'veryslow', child: Text('veryslow')),
          ],
        ),
        SizedBox(width: 90, child: TextField(controller: _w, decoration: const InputDecoration(labelText: 'Width'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        SizedBox(width: 90, child: TextField(controller: _h, decoration: const InputDecoration(labelText: 'Height'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        SizedBox(width: 120, child: TextField(controller: _audio, decoration: const InputDecoration(labelText: 'Audio kbps'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
      ],
    );
  }

  Widget _buildImageOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 120, child: TextField(controller: _imageQuality, decoration: const InputDecoration(labelText: 'Quality 0-100'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        DropdownButton<String>(
          value: _imageFormat,
          onChanged: (v) { if (v == null) return; setState(() => _imageFormat = v); _apply(); },
          items: const [
            DropdownMenuItem(value: 'jpg', child: Text('JPEG')),
            DropdownMenuItem(value: 'png', child: Text('PNG')),
            DropdownMenuItem(value: 'webp', child: Text('WebP')),
          ],
        ),
        SizedBox(width: 90, child: TextField(controller: _w, decoration: const InputDecoration(labelText: 'Width'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        SizedBox(width: 90, child: TextField(controller: _h, decoration: const InputDecoration(labelText: 'Height'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
      ],
    );
  }
}