import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/app.dart';

// You must run 'flutterfire configure' to generate firebase_options.dart
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // If firebase_options is generated:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Minimal init for now if they haven't configured:
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Init Failed (likely missing config): $e");
  }

  runApp(const ProviderScope(child: InvisPayApp()));
}
