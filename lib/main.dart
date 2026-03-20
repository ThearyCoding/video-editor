import 'dart:developer';

import 'package:ffmepg_compress_video/core/services/ffmpeg_helper.dart';
import 'package:flutter/material.dart';
import 'features/shell/view/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFmpeg
  final ffmpegHelper = FFmpegHelper();
  final initialized = await ffmpegHelper.initialize();
  
  if (!initialized) {
    log('WARNING: FFmpeg initialization failed!');
  }
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const AppShell(),
    );
  }
}
