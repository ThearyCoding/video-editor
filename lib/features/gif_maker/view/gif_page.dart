import 'package:ffmepg_compress_video/features/gif_maker/gif_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gif_bloc.dart';
import '../bloc/gif_event.dart';
import '../bloc/gif_state.dart';

class GifPage extends StatelessWidget {
  const GifPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GifBloc(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video → GIF')),
      body: BlocBuilder<GifBloc, GifState>(
        builder: (context, state) {
          final bloc = context.read<GifBloc>();
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
                      onPressed: () => bloc.add(const GifPickVideoRequested()),
                      icon: const Icon(Icons.video_library),
                      label: const Text('Select Video'),
                    ),
                    FilledButton.icon(
                      onPressed: () => bloc.add(const GifPickOutputDirRequested()),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choose Output Folder'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isProcessing || state.input == null
                          ? null
                          : () => bloc.add(const GifConvertRequested()),
                      icon: state.isProcessing
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: Text(state.isProcessing ? 'Converting…' : 'Convert'),
                    ),
                    TextButton.icon(
                      onPressed: () => bloc.add(const GifResetRequested()),
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
                _GifOptionsPanel(options: state.options),
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

class _GifOptionsPanel extends StatefulWidget {
  final GifOptions options;
  const _GifOptionsPanel({required this.options});

  @override
  State<_GifOptionsPanel> createState() => _GifOptionsPanelState();
}

class _GifOptionsPanelState extends State<_GifOptionsPanel> {
  late TextEditingController _fps, _w, _h, _speed;
  int _loop = 0;

  @override
  void initState() {
    super.initState();
    _fps = TextEditingController(text: widget.options.fps.toString());
    _w = TextEditingController(text: widget.options.width?.toString() ?? '');
    _h = TextEditingController(text: widget.options.height?.toString() ?? '');
    _speed = TextEditingController(text: widget.options.speedPercent.toString());
    _loop = widget.options.loop;
  }

  void _apply() {
    final bloc = context.read<GifBloc>();
    final o = GifOptions(
      fps: int.tryParse(_fps.text.trim()) ?? 12,
      width: _w.text.trim().isEmpty ? null : int.tryParse(_w.text.trim()),
      height: _h.text.trim().isEmpty ? null : int.tryParse(_h.text.trim()),
      loop: _loop,
      speedPercent: int.tryParse(_speed.text.trim()) ?? 100,
    );
    bloc.add(GifOptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 80, child: TextField(controller: _fps, decoration: const InputDecoration(labelText: 'FPS'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        SizedBox(width: 90, child: TextField(controller: _w, decoration: const InputDecoration(labelText: 'Width'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        SizedBox(width: 90, child: TextField(controller: _h, decoration: const InputDecoration(labelText: 'Height'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
        DropdownButton<int>(
          value: _loop,
          onChanged: (v) { if (v == null) return; setState(() => _loop = v); _apply(); },
          items: const [
            DropdownMenuItem(value: 0, child: Text('Loop: infinite')),
            DropdownMenuItem(value: 1, child: Text('Loop: once')),
          ],
        ),
        SizedBox(width: 120, child: TextField(controller: _speed, decoration: const InputDecoration(labelText: 'Speed %'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
      ],
    );
  }
}
