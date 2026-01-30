import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/app.dart';

// You must run 'flutterfire configure' to generate firebase_options.dart
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallel initialization will happen inside SplashScreen to prevent boot delay
  runApp(const ProviderScope(child: InvisPayApp()));
}
