import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/youtube_bloc.dart';
import '../bloc/youtube_event.dart';
import '../bloc/youtube_state.dart';
import '../youtube_options.dart';

class YoutubePage extends StatelessWidget {
  const YoutubePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => YoutubeBloc(),
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
          title: const Text('YouTube Downloader'),
        ),
        body: BlocBuilder<YoutubeBloc, YoutubeState>(
          builder: (context, state) {
            final bloc = context.read<YoutubeBloc>();
            final pct = (state.progress * 100).clamp(0, 100).round();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // URL Input Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'YouTube URL',
                            hintText: 'https://youtube.com/watch?v=...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                          onChanged: (url) => bloc.add(UrlChanged(url)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: state.isValidating || state.url == null
                            ? null
                            : () => bloc.add(const ValidateUrlRequested()),
                        icon: state.isValidating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(state.isValidating ? 'Validating...' : 'Validate'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Video Info Card (if available)
                  if (state.videoTitle != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          if (state.thumbnailUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                state.thumbnailUrl!,
                                width: 60,
                                height: 45,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 45,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.videoTitle!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('Channel: ${state.videoAuthor ?? "Unknown"}'),
                                Text('Duration: ${state.videoDuration ?? "Unknown"}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Output Folder & Options
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => bloc.add(const PickOutputDirRequested()),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Output Folder'),
                      ),
                      if (state.outputDirPath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '📁 ${state.outputDirPath}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Download Options
                  _YoutubeOptionsPanel(options: state.options),

                  const SizedBox(height: 16),

                  // Download Button
                  Center(
                    child: FilledButton.icon(
                      onPressed: (state.videoTitle != null && !state.isProcessing)
                          ? () => bloc.add(const DownloadRequested())
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: state.isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        state.isProcessing ? 'DOWNLOADING...' : 'DOWNLOAD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  if (state.isProcessing) ...[
                    LinearProgressIndicator(
                      value: state.progress > 0 ? state.progress : null,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text('Progress: $pct%')),
                  ],

                  // Output File Info
                  if (state.output != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✅ Download Complete!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  state.output!.path,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () => bloc.add(const RevealInFinderRequested()),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Reset Button
                  if (state.url != null || state.videoTitle != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: state.isProcessing
                            ? null
                            : () => bloc.add(const ResetRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear All'),
                      ),
                    ),

                  const Spacer(),

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
                          state.log + (state.error != null ? '\n❌ Error: ${state.error}' : ''),
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
}

class _YoutubeOptionsPanel extends StatefulWidget {
  final YoutubeOptions options;
  const _YoutubeOptionsPanel({required this.options});

  @override
  State<_YoutubeOptionsPanel> createState() => _YoutubeOptionsPanelState();
}

class _YoutubeOptionsPanelState extends State<_YoutubeOptionsPanel> {
  late DownloadFormat _format;
  String? _videoQuality;
  String? _audioBitrate;
  bool _downloadPlaylist = false;

  final List<String> _videoQualities = ['1080p', '720p', '480p', '360p'];
  final List<String> _audioBitrates = ['128kbps', '192kbps', '256kbps', '320kbps'];

  @override
  void initState() {
    super.initState();
    _format = widget.options.format;
    _videoQuality = widget.options.videoQuality ?? '720p';
    _audioBitrate = widget.options.audioBitrate ?? '192kbps';
    _downloadPlaylist = widget.options.downloadPlaylist;
  }

  void _apply() {
    final bloc = context.read<YoutubeBloc>();
    final o = YoutubeOptions(
      format: _format,
      videoQuality: _videoQuality,
      audioBitrate: _audioBitrate,
      downloadPlaylist: _downloadPlaylist,
    );
    bloc.add(OptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        

        // Quality selector (for video)
        if (_format == DownloadFormat.video)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: _videoQuality,
              underline: const SizedBox(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _videoQuality = v);
                _apply();
              },
              items: _videoQualities.map((q) {
                return DropdownMenuItem(value: q, child: Text(q));
              }).toList(),
            ),
          ),

        // Bitrate selector (for audio)
        if (_format == DownloadFormat.audio)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: _audioBitrate,
              underline: const SizedBox(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _audioBitrate = v);
                _apply();
              },
              items: _audioBitrates.map((b) {
                return DropdownMenuItem(value: b, child: Text(b));
              }).toList(),
            ),
          ),

        // Playlist option
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _downloadPlaylist,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _downloadPlaylist = v);
                _apply();
              },
            ),
            const Text('Playlist'),
          ],
        ),
      ],
    );
  }
}