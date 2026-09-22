import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/start_screen.dart';
import 'data/word_dictionary.dart';
import 'services/consent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await WordDictionary.init();
  runApp(const MyApp());
  // Onay formu uygulama arayüzü açıldıktan sonra gösterilir; MobileAds da
  // yalnızca onay alındıktan sonra ConsentService içinde başlatılır.
  ConsentService.gatherConsent();
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
