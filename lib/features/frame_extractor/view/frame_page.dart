import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/frame_bloc.dart';
import '../bloc/frame_event.dart';
import '../bloc/frame_state.dart';
import '../models/frame_options.dart';

class FramePage extends StatelessWidget {
  const FramePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => FrameBloc(), child: const _View());
  }
}

class _View extends StatelessWidget {
  const _View();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frame Extractor')),
      body: BlocBuilder<FrameBloc, FrameState>(
        builder: (context, state) {
      final bloc = context.read<FrameBloc>();
      final pct = (state.progress * 100).clamp(0, 100).round();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => bloc.add(const FramePickVideoRequested()), icon: const Icon(Icons.video_library), label: const Text('Select Video')),
            FilledButton.icon(onPressed: () => bloc.add(const FramePickOutputDirRequested()), icon: const Icon(Icons.folder_open), label: const Text('Choose Output Folder')),
            FilledButton.icon(
              onPressed: state.isProcessing || state.input == null ? null : () => bloc.add(const FrameExtractRequested()),
              icon: state.isProcessing ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.image),
              label: Text(state.isProcessing ? 'Extracting…' : 'Extract'),
            ),
            TextButton.icon(onPressed: () => bloc.add(const FrameResetRequested()), icon: const Icon(Icons.refresh), label: const Text('Reset')),
          ]),
          const SizedBox(height: 12),
          if (state.outputDirPath != null) Text('Output folder: ${state.outputDirPath}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (state.input != null) Text('Input: ${state.input!.path}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (state.isProcessing) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: state.progress > 0 ? state.progress : null),
            const SizedBox(height: 8),
            Text('Progress: $pct%'),
          ],
          const SizedBox(height: 12),
          _OptionsPanel(options: state.options),
          const SizedBox(height: 16),
          const Text('Logs', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(child: Text(state.log + (state.error != null ? '\n❌ ${state.error}' : ''), style: const TextStyle(fontFamily: 'monospace'))),
          )),
        ]),
      );
    }),
    );
  }
}

class _OptionsPanel extends StatefulWidget {
  final FrameOptions options;
  const _OptionsPanel({required this.options});
  @override State<_OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<_OptionsPanel> {
  late TextEditingController _sec, _w, _h;
  String _fmt = 'png';
  @override void initState() {
    super.initState();
    _sec = TextEditingController(text: widget.options.everySec.toString());
    _w = TextEditingController(text: widget.options.width?.toString() ?? '');
    _h = TextEditingController(text: widget.options.height?.toString() ?? '');
    _fmt = widget.options.format;
  }
  void _apply() {
    final bloc = context.read<FrameBloc>();
    final o = FrameOptions(
      everySec: int.tryParse(_sec.text.trim()) ?? 1,
      format: _fmt,
      width: _w.text.trim().isEmpty ? null : int.tryParse(_w.text.trim()),
      height: _h.text.trim().isEmpty ? null : int.tryParse(_h.text.trim()),
    );
    bloc.add(FrameOptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 8, children: [
      SizedBox(width: 120, child: TextField(controller: _sec, decoration: const InputDecoration(labelText: 'Every N seconds'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
      DropdownButton<String>(
        value: _fmt,
        items: const [DropdownMenuItem(value: 'png', child: Text('PNG')), DropdownMenuItem(value: 'jpg', child: Text('JPG'))],
        onChanged: (v) { if (v==null) return; setState(()=>_fmt=v); _apply(); },
      ),
      SizedBox(width: 100, child: TextField(controller: _w, decoration: const InputDecoration(labelText: 'Width'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
      SizedBox(width: 100, child: TextField(controller: _h, decoration: const InputDecoration(labelText: 'Height'), keyboardType: TextInputType.number, onChanged: (_) => _apply())),
    ]);
  }
}
