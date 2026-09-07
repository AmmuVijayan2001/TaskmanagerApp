import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter appRouter(Object? firebaseError) => GoRouter(
      initialLocation: firebaseError == null ? '/splash' : '/setup-required',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const _SplashPage(),
        ),
        GoRoute(
          path: '/setup-required',
          builder: (_, __) => _SetupRequiredPage(error: firebaseError),
        ),
      ],
    );

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _SetupRequiredPage extends StatelessWidget {
  const _SetupRequiredPage({required this.error});

  final Object? error;

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
                    'Add your Firebase configuration (google-services.json for Android and GoogleService-Info.plist for iOS), then restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
