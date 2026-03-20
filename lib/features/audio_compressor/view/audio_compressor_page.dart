import 'package:ffmepg_compress_video/features/audio_compressor/audio_compressor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/audio_compressor_bloc.dart';
import '../bloc/audio_compressor_event.dart';
import '../bloc/audio_compressor_state.dart';

class AudioCompressorPage extends StatelessWidget {
  const AudioCompressorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AudioCompressorBloc(),
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<AudioCompressorBloc, AudioCompressorState>(
            builder: (context, state) {
              final bloc = context.read<AudioCompressorBloc>();
              return AppBar(
                title: const Text('Audio Compressor'),
                actions: [
                  if (state.isPreviewing)
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () => bloc.add(const StopPreviewRequested()),
                      tooltip: 'Stop Preview',
                    ),
                ],
              );
            },
          ),
        ),
        body: BlocBuilder<AudioCompressorBloc, AudioCompressorState>(
          builder: (context, state) {
            final bloc = context.read<AudioCompressorBloc>();
            final pct = (state.progress * 100).clamp(0, 100).round();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Controls
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => bloc.add(const PickAudioRequested()),
                        icon: const Icon(Icons.audio_file),
                        label: const Text('Select Audio'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            bloc.add(const PickOutputDirRequested()),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Output Folder'),
                      ),
                      if (state.inputFile != null && !state.isPreviewing)
                        FilledButton.icon(
                          onPressed: () =>
                              bloc.add(const PreviewAudioRequested()),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Preview'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      FilledButton.icon(
                        onPressed:
                            (state.inputFile != null && !state.isProcessing)
                                ? () => bloc.add(const CompressAudioRequested())
                                : null,
                        icon: state.isProcessing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.compress),
                        label: Text(
                            state.isProcessing ? 'Compressing…' : 'Compress'),
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

                  const SizedBox(height: 16),

                  // Audio Info Card
                  if (state.inputFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Album Art Thumbnail
                          if (state.hasAlbumArt &&
                              state.albumArtThumbnail != null)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: MemoryImage(state.albumArtThumbnail!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (state.hasAlbumArt)
                            // Has album art but failed to extract
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child:
                                  const Icon(Icons.album, color: Colors.grey),
                            )
                          else
                            // No album art
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.audio_file,
                                  color: Colors.grey),
                            ),
                          const SizedBox(width: 12),

                          // Audio Metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.title != null)
                                  Text(
                                    state.title!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (state.artist != null)
                                  Text(
                                    'Artist: ${state.artist}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if (state.album != null)
                                  Text(
                                    'Album: ${state.album}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.timer,
                                      label: _formatDuration(state.duration),
                                    ),
                                    if (state.originalBitrate != null)
                                      _buildInfoChip(
                                        icon: Icons.speed,
                                        label: '${state.originalBitrate} kbps',
                                      ),
                                    if (state.originalSampleRate != null)
                                      _buildInfoChip(
                                        icon: Icons.graphic_eq,
                                        label:
                                            '${state.originalSampleRate! ~/ 1000} kHz',
                                      ),
                                    if (state.hasAlbumArt)
                                      _buildInfoChip(
                                        icon: Icons.image,
                                        label: 'Has Art',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Output Folder
                  if (state.outputDirPath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '📁 Output: ${state.outputDirPath}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Compression Options
                  _AudioOptionsPanel(options: state.options),

                  const SizedBox(height: 16),

                  // Progress Bar
                  if (state.isProcessing) ...[
                    LinearProgressIndicator(
                      value: state.progress > 0 ? state.progress : null,
                    ),
                    const SizedBox(height: 8),
                    Text('Progress: $pct%'),
                  ],

                  // Output File
                  if (state.outputFile != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
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
                                  '✅ Compression Complete!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  state.outputFile!.path,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () =>
                                bloc.add(const RevealInFinderRequested()),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                          state.log +
                              (state.error != null
                                  ? '\n❌ Error: ${state.error}'
                                  : ''),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
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

  String _formatDuration(int? seconds) {
    if (seconds == null) return '?:??';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
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
  late AudioFormat _format;
  late AudioQuality _quality;
  late int? _sampleRate;
  late ChannelMode _channelMode;
  late bool _preserveMetadata;
  late bool _preserveAlbumArt;
  late bool _removeAlbumArt; // Add this
  late bool _normalizeVolume;
  late double? _volumeTarget;
  late bool _removeSilence;
  late double? _silenceThreshold;
  late bool _fadeInOut;
  late double? _fadeDuration;
  late bool _trimSilence;
  late double? _startTime;
  late double? _endTime;

  final List<int> _sampleRates = [
    8000,
    11025,
    16000,
    22050,
    32000,
    44100,
    48000,
    88200,
    96000
  ];

  @override
  void initState() {
    super.initState();
    _format = widget.options.format;
    _quality = widget.options.quality;
    _sampleRate = widget.options.sampleRate;
    _channelMode = widget.options.channelMode;
    _preserveMetadata = widget.options.preserveMetadata;
    _preserveAlbumArt = widget.options.preserveAlbumArt;
    _removeAlbumArt = widget.options.removeAlbumArt; // Initialize
    _normalizeVolume = widget.options.normalizeVolume;
    _volumeTarget = widget.options.volumeTarget;
    _removeSilence = widget.options.removeSilence;
    _silenceThreshold = widget.options.silenceThreshold;
    _fadeInOut = widget.options.fadeInOut;
    _fadeDuration = widget.options.fadeDuration;
    _trimSilence = widget.options.trimSilence;
    _startTime = widget.options.startTime;
    _endTime = widget.options.endTime;
  }

  void _apply() {
    final bloc = context.read<AudioCompressorBloc>();
    final o = AudioOptions(
      format: _format,
      quality: _quality,
      sampleRate: _sampleRate,
      channelMode: _channelMode,
      preserveMetadata: _preserveMetadata,
      preserveAlbumArt: _preserveAlbumArt,
      removeAlbumArt: _removeAlbumArt, // Add this
      normalizeVolume: _normalizeVolume,
      volumeTarget: _volumeTarget,
      removeSilence: _removeSilence,
      silenceThreshold: _silenceThreshold,
      fadeInOut: _fadeInOut,
      fadeDuration: _fadeDuration,
      trimSilence: _trimSilence,
      startTime: _startTime,
      endTime: _endTime,
    );
    bloc.add(AudioOptionsChanged(o));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Compression Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Basic Options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Format
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<AudioFormat>(
                    value: _format,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _format = v);
                      _apply();
                    },
                    items: const [
                      DropdownMenuItem(
                          value: AudioFormat.mp3, child: Text('MP3')),
                      DropdownMenuItem(
                          value: AudioFormat.aac, child: Text('AAC')),
                      DropdownMenuItem(
                          value: AudioFormat.ogg, child: Text('OGG')),
                      DropdownMenuItem(
                          value: AudioFormat.m4a, child: Text('M4A')),
                      DropdownMenuItem(
                          value: AudioFormat.wav, child: Text('WAV')),
                    ],
                  ),
                ),

                // Quality/Bitrate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<AudioQuality>(
                    value: _quality,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _quality = v);
                      _apply();
                    },
                    items: AudioQuality.values.map((q) {
                      return DropdownMenuItem(
                        value: q,
                        child: Text(q.label),
                      );
                    }).toList(),
                  ),
                ),

                // Sample Rate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<int?>(
                    value: _sampleRate,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      setState(() => _sampleRate = v);
                      _apply();
                    },
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Auto Sample Rate')),
                      ..._sampleRates.map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text('${rate ~/ 1000} kHz'),
                        );
                      }),
                    ],
                  ),
                ),

                // Channel Mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<ChannelMode>(
                    value: _channelMode,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _channelMode = v);
                      _apply();
                    },
                    items: ChannelMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Advanced Options
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Preserve Metadata
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _preserveMetadata,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _preserveMetadata = v);
                        _apply();
                      },
                    ),
                    const Text('Preserve Metadata'),
                  ],
                ),

                // Album Art Options (only for MP3/M4A)
                if (_format == AudioFormat.mp3 || _format == AudioFormat.m4a) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _preserveAlbumArt,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _preserveAlbumArt = v;
                            if (v) _removeAlbumArt = false; // Can't have both
                          });
                          _apply();
                        },
                      ),
                      const Text('Preserve Album Art'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _removeAlbumArt,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _removeAlbumArt = v;
                            if (v) _preserveAlbumArt = false; // Can't have both
                          });
                          _apply();
                        },
                      ),
                      const Text('Remove Album Art'),
                    ],
                  ),
                ],

                // Normalize Volume
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _normalizeVolume,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _normalizeVolume = v);
                        if (!v) _volumeTarget = null;
                        _apply();
                      },
                    ),
                    const Text('Normalize Volume'),
                  ],
                ),

                // Remove Silence
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _removeSilence,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _removeSilence = v);
                        if (!v) _silenceThreshold = null;
                        _apply();
                      },
                    ),
                    const Text('Remove Silence'),
                  ],
                ),

                // Fade In/Out
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _fadeInOut,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _fadeInOut = v);
                        if (!v) _fadeDuration = null;
                        _apply();
                      },
                    ),
                    const Text('Fade In/Out'),
                  ],
                ),

                // Trim
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _trimSilence,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _trimSilence = v);
                        if (!v) {
                          _startTime = null;
                          _endTime = null;
                        }
                        _apply();
                      },
                    ),
                    const Text('Trim'),
                  ],
                ),
              ],
            ),

            // Numeric inputs for advanced options
            if (_normalizeVolume && _volumeTarget != null ||
                _removeSilence && _silenceThreshold != null ||
                _fadeInOut && _fadeDuration != null ||
                _trimSilence)
              const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_normalizeVolume)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Volume (dB)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _volumeTarget = double.tryParse(v);
                        _apply();
                      },
                    ),
                  ),
                if (_removeSilence)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Silence (dB)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _silenceThreshold = double.tryParse(v);
                        _apply();
                      },
                    ),
                  ),
                if (_fadeInOut)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Fade (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _fadeDuration = double.tryParse(v);
                        _apply();
                      },
                    ),
                  ),
                if (_trimSilence) ...[
                  SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Start (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _startTime = double.tryParse(v);
                        _apply();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'End (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _endTime = double.tryParse(v);
                        _apply();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}