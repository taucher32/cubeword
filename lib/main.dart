import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/start_screen.dart';
import 'data/word_dictionary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (Platform.isAndroid || Platform.isIOS) {
    if (!const bool.fromEnvironment('dart.vm.product')) {
      try {
        await MobileAds.instance.initialize();
      } catch (_) {}
    } else {
      await MobileAds.instance.initialize();
    }
  }
  await WordDictionary.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cubeword',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StartScreen(),
    );
  }
}
