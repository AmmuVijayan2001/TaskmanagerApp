import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/app_theme.dart';
import '../core/presentation/router.dart';

final firebaseInitializationErrorProvider = Provider<Object?>((ref) => null);

class SmartTaskManagerApp extends ConsumerWidget {
  const SmartTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseError = ref.watch(firebaseInitializationErrorProvider);

    return MaterialApp.router(
      title: 'Smart Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter(firebaseError),
    );
  }
}
