
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:frontend/pages/login_page.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  material.WidgetsFlutterBinding.ensureInitialized();

  // Skip Firebase initialization only for the native Linux UI preview.
  // On web, defaultTargetPlatform may still report Linux depending on the
  // browser, but Firebase must be initialized before FirebaseAuth is read.
  final isNativeLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  if (!isNativeLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  material.runApp(const JeevSwasthApp());
}

class JeevSwasthApp extends material.StatelessWidget {
  const JeevSwasthApp({super.key});

  @override
  material.Widget build(material.BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final material.ColorScheme lightScheme = lightDynamic == null
            ? material.ColorScheme.fromSeed(
                seedColor: const material.Color(0xFF6750A4),
                brightness: material.Brightness.light,
              )
            : material.ColorScheme.fromSeed(
                seedColor: lightDynamic.primary,
                brightness: material.Brightness.light,
              );

        final material.ColorScheme darkScheme = darkDynamic == null
            ? material.ColorScheme.fromSeed(
                seedColor: const material.Color(0xFFD0BCFF),
                brightness: material.Brightness.dark,
              )
            : material.ColorScheme.fromSeed(
                seedColor: darkDynamic.primary,
                brightness: material.Brightness.dark,
              );

        return material.MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          themeMode: material.ThemeMode.system,
          home: const LoginPage(),
        );
      },
    );
  }
}
