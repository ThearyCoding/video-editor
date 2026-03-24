import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/media_compress_bloc.dart';
import '../bloc/media_compress_event.dart';
import '../bloc/media_compress_state.dart';
import '../compression_options.dart' as mymodel;

class MediaCompressorPage extends StatelessWidget {
  const MediaCompressorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MediaCompressBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Compressor'),
        elevation: 2,
      ),
      body: BlocBuilder<MediaCompressBloc, MediaCompressState>(
        builder: (context, state) {
          final bloc = context.read<MediaCompressBloc>();
          final pct = (state.progress * 100).clamp(0, 100).round();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Type Selector
                SegmentedButton<mymodel.MediaType>(
                  segments: const [
                    ButtonSegment(
                      value: mymodel.MediaType.video,
                      label: Text('Video'),
                      icon: Icon(Icons.videocam),
                    ),
                    ButtonSegment(
                      value: mymodel.MediaType.image,
                      label: Text('Image'),
                      icon: Icon(Icons.image),
                    ),
                  ],
                  selected: {state.options.mediaType},
                  onSelectionChanged: (Set<mymodel.MediaType> selection) {
                    bloc.add(MediaTypeChanged(selection.first));
                  },
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
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
                      icon: Icon(state.options.mediaType == mymodel.MediaType.video 
                        ? Icons.video_library 
                        : Icons.image),
                      label: Text(state.options.mediaType == mymodel.MediaType.video 
                        ? 'Select Video' 
                        : 'Select Image'),
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
                          ? const SizedBox(
                              height: 18, 
                              width: 18, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
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
                
                // File Info - Generic media info
                if (state.outputDirPath != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📁 Output: ${state.outputDirPath}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                if (state.input != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '📂 Source: ${state.input!.path.split('/').last}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                if (state.output != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '💾 Result: ${state.output!.path.split('/').last}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 16),
                
                // Progress Indicator
                if (state.isProcessing) ...[
                  LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progress: $pct%',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],

                const SizedBox(height: 16),
                
                // Options Panel
                _OptionsPanel(options: state.options),

                const SizedBox(height: 16),
                
                // Logs Section
                const Text(
                  'Logs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        state.log + (state.error != null ? '\n❌ ${state.error}' : ''),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
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

// Options Panel Widget
class _OptionsPanel extends StatefulWidget {
  final mymodel.CompressionOptions options;
  const _OptionsPanel({required this.options});

  @override
  State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  late TextEditingController _crf;
  late TextEditingController _w;
  late TextEditingController _h;
  late TextEditingController _audio;
  late TextEditingController _imageQuality;
  late TextEditingController _targetSize;
  
  String _codec = 'libx264';
  String _preset = 'fast';
  String _imageFormat = 'jpg';
  bool _useTargetSize = false;

  @override
  void initState() {
    super.initState();
    _crf = TextEditingController(text: widget.options.crf.toString());
    _w = TextEditingController(text: widget.options.width?.toString() ?? '');
    _h = TextEditingController(text: widget.options.height?.toString() ?? '');
    _audio = TextEditingController(text: widget.options.audioBitrateK.toString());
    _imageQuality = TextEditingController(text: widget.options.imageQuality.toString());
    _targetSize = TextEditingController(text: widget.options.targetSizeKB?.toString() ?? '500');
    _codec = widget.options.vCodec;
    _preset = widget.options.preset;
    _imageFormat = widget.options.imageFormat;
    _useTargetSize = widget.options.targetSizeKB != null;
  }

  @override
  void dispose() {
    _crf.dispose();
    _w.dispose();
    _h.dispose();
    _audio.dispose();
    _imageQuality.dispose();
    _targetSize.dispose();
    super.dispose();
  }

  void _apply() {
    final o = mymodel.CompressionOptions(
      mediaType: widget.options.mediaType,
      vCodec: _codec,
      crf: int.tryParse(_crf.text.trim()) ?? 24,
      preset: _preset,
      imageQuality: int.tryParse(_imageQuality.text.trim()) ?? 85,
      imageFormat: _imageFormat,
      targetSizeKB: _useTargetSize ? int.tryParse(_targetSize.text.trim()) : null,
      width: _w.text.trim().isEmpty ? null : int.tryParse(_w.text.trim()),
      height: _h.text.trim().isEmpty ? null : int.tryParse(_h.text.trim()),
      audioBitrateK: int.tryParse(_audio.text.trim()) ?? 128,
    );
    
    final bloc = context.read<MediaCompressBloc>();
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _crf,
                  decoration: const InputDecoration(
                    labelText: 'CRF',
                    helperText: '18-28',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
              DropdownButton<String>(
                value: _codec,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _codec = v);
                  _apply();
                },
                items: const [
                  DropdownMenuItem(value: 'libx264', child: Text('H.264')),
                  DropdownMenuItem(value: 'libx265', child: Text('H.265')),
                ],
              ),
              DropdownButton<String>(
                value: _preset,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _preset = v);
                  _apply();
                },
                items: const [
                  DropdownMenuItem(value: 'ultrafast', child: Text('Ultrafast')),
                  DropdownMenuItem(value: 'superfast', child: Text('Superfast')),
                  DropdownMenuItem(value: 'veryfast', child: Text('Veryfast')),
                  DropdownMenuItem(value: 'faster', child: Text('Faster')),
                  DropdownMenuItem(value: 'fast', child: Text('Fast')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'slow', child: Text('Slow')),
                  DropdownMenuItem(value: 'slower', child: Text('Slower')),
                  DropdownMenuItem(value: 'veryslow', child: Text('Veryslow')),
                ],
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _w,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _h,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _audio,
                  decoration: const InputDecoration(
                    labelText: 'Audio (kbps)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Target size toggle section
          Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _useTargetSize,
                        onChanged: (value) {
                          setState(() {
                            _useTargetSize = value ?? false;
                          });
                          _apply();
                        },
                      ),
                      const Text(
                        'Target file size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_useTargetSize) ...[
                        const Text('Max: '),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _targetSize,
                            decoration: const InputDecoration(
                              labelText: 'KB',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _apply(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_useTargetSize)
                    const Padding(
                      padding: EdgeInsets.only(left: 36.0, top: 8.0),
                      child: Text(
                        'Quality will be automatically adjusted to reach target size',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Compression options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Quality slider (only shown when not using target size)
              if (!_useTargetSize) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality: ${_imageQuality.text}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      width: 250,
                      child: Slider(
                        value: double.tryParse(_imageQuality.text) ?? 85,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: _imageQuality.text,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          _imageQuality.text = value.round().toString();
                          _apply();
                        },
                      ),
                    ),
                  ],
                ),
              ],
              
              // Format selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _imageFormat,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _imageFormat = v);
                    _apply();
                  },
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'jpg', child: Text('JPEG')),
                    DropdownMenuItem(value: 'png', child: Text('PNG')),
                    DropdownMenuItem(value: 'webp', child: Text('WebP')),
                  ],
                ),
              ),
              
              // Width input
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _w,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
              
              // Height input
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _h,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _apply(),
                ),
              ),
            ],
          ),
          
          // Info about file sizes
          if (widget.options.targetSizeKB != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target size: ${widget.options.targetSizeKB} KB. '
                        'The app will automatically find the best quality to achieve this size.',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}