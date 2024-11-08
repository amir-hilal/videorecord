import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videorecord/providers/video_modal_provider.dart';
import 'providers/video_provider.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => VideoModalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
