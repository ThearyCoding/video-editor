import 'package:ffmepg_compress_video/features/merge_media/bloc/merge_bloc.dart';
import 'package:ffmepg_compress_video/features/merge_media/bloc/merge_event.dart';
import 'package:ffmepg_compress_video/features/merge_media/bloc/merge_state.dart';
import 'package:ffmepg_compress_video/features/merge_media/merge_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioVideoMergePage extends StatelessWidget {
  const AudioVideoMergePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MergeBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Merger'),
        ),
        body: BlocBuilder<MergeBloc, MergeState>(
          builder: (context, state) {
            final bloc = context.read<MergeBloc>();
            final pct = (state.progress * 100).clamp(0, 100).round();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merge Type Selector
                  SegmentedButton<MergeType>(
                    segments: const [
                      ButtonSegment(
                        value: MergeType.videoAudio,
                        label: Text('Video + Audio'),
                        icon: Icon(Icons.videocam),
                      ),
                      ButtonSegment(
                        value: MergeType.imageAudio,
                        label: Text('Image + Audio'),
                        icon: Icon(Icons.image),
                      ),
                    ],
                    selected: {state.mergeType},
                    onSelectionChanged: (Set<MergeType> selection) {
                      bloc.add(MergeTypeChanged(selection.first));
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Main Controls
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (state.mergeType == MergeType.videoAudio)
                        FilledButton.icon(
                          onPressed: () => bloc.add(const PickVideoRequested()),
                          icon: const Icon(Icons.video_library),
                          label: const Text('Select Video'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => bloc.add(const PickImageRequested()),
                          icon: const Icon(Icons.image),
                          label: const Text('Select Image'),
                        ),
                      
                      FilledButton.icon(
                        onPressed: () => bloc.add(const PickAudioRequested()),
                        icon: const Icon(Icons.audiotrack),
                        label: const Text('Select Audio'),
                      ),
                      
                      FilledButton.icon(
                        onPressed: () => bloc.add(const PickOutputDirRequested()),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Output Folder'),
                      ),
                      
                      FilledButton.icon(
                        onPressed: _canMerge(state)
                            ? () => bloc.add(const MergeRequested())
                            : null,
                        icon: state.isProcessing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.merge_type),
                        label: Text(state.isProcessing ? 'Merging…' : 'Merge'),
                      ),
                      
                      TextButton.icon(
                        onPressed: state.isProcessing
                            ? null
                            : () => bloc.add(const ResetRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // File Info
                  if (state.outputDirPath != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Output Folder:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(state.outputDirPath!),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 8),
                  
                  if (state.mergeType == MergeType.videoAudio && state.videoFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(state.videoFile!.path),
                        ],
                      ),
                    ),
                    
                  if (state.mergeType == MergeType.imageAudio && state.imageFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(state.imageFile!.path),
                        ],
                      ),
                    ),
                    
                  if (state.audioFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Audio:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(state.audioFile!.path),
                        ],
                      ),
                    ),
                    
                  if (state.output != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Output:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(state.output!.path),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  if (state.isProcessing) ...[
                    LinearProgressIndicator(
                      value: state.progress > 0 ? state.progress : null,
                    ),
                    const SizedBox(height: 8),
                    Text('Progress: $pct%'),
                    const SizedBox(height: 12),
                  ],

                  // Merge Options
                  _MergeOptionsPanel(options: state.options),

                  const SizedBox(height: 16),

                  // Logs Section
                  const Text(
                    'Logs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                          state.log + (state.error != null ? '\n\n❌ Error: ${state.error}' : ''),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  bool _canMerge(MergeState state) {
    if (state.isProcessing) return false;
    
    if (state.mergeType == MergeType.videoAudio) {
      return state.videoFile != null && state.audioFile != null;
    } else {
      return state.imageFile != null && state.audioFile != null;
    }
  }
}

class _MergeOptionsPanel extends StatefulWidget {
  final MergeOptions options;
  const _MergeOptionsPanel({required this.options});

  @override
  State<_MergeOptionsPanel> createState() => _MergeOptionsPanelState();
}

class _MergeOptionsPanelState extends State<_MergeOptionsPanel> {
  late TextEditingController _videoBitrate;
  late TextEditingController _audioBitrate;
  String _codec = 'libx264';
  bool _shortestAudio = true;

  @override
  void initState() {
    super.initState();
    _videoBitrate = TextEditingController(text: widget.options.videoBitrateKbps.toString());
    _audioBitrate = TextEditingController(text: widget.options.audioBitrateKbps.toString());
    _codec = widget.options.videoCodec;
    _shortestAudio = widget.options.useShortestAudio;
  }

  @override
  void dispose() {
    _videoBitrate.dispose();
    _audioBitrate.dispose();
    super.dispose();
  }

  void _apply() {
    final bloc = context.read<MergeBloc>();
    final o = MergeOptions(
      videoCodec: _codec,
      videoBitrateKbps: int.tryParse(_videoBitrate.text.trim()) ?? 2000,
      audioBitrateKbps: int.tryParse(_audioBitrate.text.trim()) ?? 192,
      useShortestAudio: _shortestAudio,
    );
    bloc.add(MergeOptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merge Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Video Bitrate
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _videoBitrate,
                    decoration: const InputDecoration(
                      labelText: 'Video kbps',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _apply(),
                  ),
                ),
                
                // Audio Bitrate
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _audioBitrate,
                    decoration: const InputDecoration(
                      labelText: 'Audio kbps',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _apply(),
                  ),
                ),
                
                // Codec Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: _codec,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _codec = v);
                      _apply();
                    },
                    items: const [
                      DropdownMenuItem(value: 'libx264', child: Text('H.264')),
                      DropdownMenuItem(value: 'libx265', child: Text('H.265 (HEVC)')),
                      DropdownMenuItem(value: 'mpeg4', child: Text('MPEG-4')),
                    ],
                  ),
                ),
                
                // Shortest Audio Checkbox
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _shortestAudio,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _shortestAudio = v);
                        _apply();
                      },
                    ),
                    const Text('Trim to shortest'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}