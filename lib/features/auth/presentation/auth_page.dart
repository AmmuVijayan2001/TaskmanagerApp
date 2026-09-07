import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isRegistration = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Smart Task Manager',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(_isRegistration ? 'Create an account to get started.' : 'Welcome back.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    if (_isRegistration) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter your name.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => value != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)
                          ? null
                          : 'Enter a valid email address.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: [if (_isRegistration) AutofillHints.newPassword else AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : 'Password must be at least 6 characters.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: isLoading
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isRegistration ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() => _isRegistration = !_isRegistration),
                      child: Text(_isRegistration ? 'Already have an account? Sign in' : 'New here? Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegistration) {
      controller.register(_nameController.text, _emailController.text, _passwordController.text);
    } else {
      controller.signIn(_emailController.text, _passwordController.text);
    }
  }
}
