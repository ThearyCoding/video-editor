import 'package:ffmepg_compress_video/features/audio_extractor/view/audio_page.dart';
import 'package:ffmepg_compress_video/features/compressor/view/compressor_page.dart';
import 'package:ffmepg_compress_video/features/gif_maker/view/gif_page.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    CompressorPage(),
    GifPage(),
    AudioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.compress),
                label: Text('Compress'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.gif_box_outlined),
                label: Text('Video → GIF'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.audiotrack),
                label: Text('MP4 → MP3'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }
}
