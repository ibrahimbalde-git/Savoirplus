import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ajouter
import 'firebase_options.dart'; // Fichier généré par flutterfire
import 'pages/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Activer la persistance de la session (reste connecté même après redémarrage)
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  print("🔥 Firebase initialisé !");
  print("🔥 Projet ID : ${DefaultFirebaseOptions.currentPlatform.projectId}");

  runApp(SavoirPlusApp());
}

class SavoirPlusApp extends StatefulWidget {
  @override
  State<SavoirPlusApp> createState() => _SavoirPlusAppState();
}

class _SavoirPlusAppState extends State<SavoirPlusApp> {
  Locale _locale = WidgetsBinding.instance.platformDispatcher.locale;

  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Savoir+',
      theme: ThemeData(primarySwatch: Colors.indigo),
      locale: _locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthGate(onLocaleChange: setLocale),
    );
  }
}
