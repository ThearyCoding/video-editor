import 'package:ffmepg_compress_video/features/audio_extractor/audio_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/audio_bloc.dart';
import '../bloc/audio_event.dart';
import '../bloc/audio_state.dart';

class AudioPage extends StatelessWidget {
  const AudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AudioBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MP4 → MP3')),
      body: BlocBuilder<AudioBloc, AudioState>(
        builder: (context, state) {
          final bloc = context.read<AudioBloc>();
          final pct = (state.progress * 100).clamp(0, 100).round();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => bloc.add(const AudioPickVideoRequested()),
                      icon: const Icon(Icons.video_library),
                      label: const Text('Select MP4'),
                    ),
                    FilledButton.icon(
                      onPressed: () => bloc.add(const AudioPickOutputDirRequested()),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choose Output Folder'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isProcessing || state.input == null
                          ? null
                          : () => bloc.add(const AudioExtractRequested()),
                      icon: state.isProcessing
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: Text(state.isProcessing ? 'Extracting…' : 'Extract'),
                    ),
                    TextButton.icon(
                      onPressed: () => bloc.add(const AudioResetRequested()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.outputDirPath != null) Text('Output folder: ${state.outputDirPath}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (state.input != null) Text('Input: ${state.input!.path}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (state.output != null) Text('Output: ${state.output!.path}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (state.isProcessing) ...[
                  LinearProgressIndicator(value: state.progress > 0 ? state.progress : null),
                  const SizedBox(height: 8),
                  Text('Progress: $pct%'),
                ],
                const SizedBox(height: 12),
                _AudioOptionsPanel(options: state.options),
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

class _AudioOptionsPanel extends StatefulWidget {
  final AudioOptions options;
  const _AudioOptionsPanel({required this.options});

  @override
  State<_AudioOptionsPanel> createState() => _AudioOptionsPanelState();
}

class _AudioOptionsPanelState extends State<_AudioOptionsPanel> {
  late TextEditingController _bitrate;

  @override
  void initState() {
    super.initState();
    _bitrate = TextEditingController(text: widget.options.bitrateK.toString());
  }

  void _apply() {
    final bloc = context.read<AudioBloc>();
    final o = AudioOptions(bitrateK: int.tryParse(_bitrate.text.trim()) ?? 192);
    bloc.add(AudioOptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 120,
          child: TextField(
            controller: _bitrate,
            decoration: const InputDecoration(labelText: 'Bitrate (kbps)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _apply(),
          ),
        ),
      ],
    );
  }
}
