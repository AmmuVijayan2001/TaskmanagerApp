import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/app_theme.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/dashboard_page.dart';

final firebaseInitializationErrorProvider = Provider<Object?>((ref) => null);

class SmartTaskManagerApp extends ConsumerWidget {
  const SmartTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseError = ref.watch(firebaseInitializationErrorProvider);

    return MaterialApp(
      title: 'Smart Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(appThemeModeProvider),
      home: firebaseError != null
          ? const _SetupRequiredPage()
          : ref.watch(authStateProvider).when(
                loading: () => const _SplashPage(),
                error: (_, __) => const _StartupErrorPage(),
                data: (user) => user == null ? const AuthPage() : const DashboardPage(),
              ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Unable to restore your session. Please restart the app.')),
      );
}

class _SetupRequiredPage extends StatelessWidget {
  const _SetupRequiredPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_suggest_outlined,
                      size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Firebase setup required',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'Check the Firebase configuration files, then restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
