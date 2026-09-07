import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Object? initializationError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    initializationError = error;
  }

  runApp(
    ProviderScope(
      overrides: [firebaseInitializationErrorProvider.overrideWithValue(initializationError)],
      child: const SmartTaskManagerApp(),
    ),
  );
}
