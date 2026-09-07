import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';
import 'auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.profile});
  final UserProfile profile;
  @override ConsumerState<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _name;
  late String _theme;
  @override void initState() { super.initState(); _name = TextEditingController(text: widget.profile.name); _theme = widget.profile.themeMode; }
  @override void dispose() { _name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile & appearance')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
      const SizedBox(height: 16),
      Text(widget.profile.email, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(value: _theme, decoration: const InputDecoration(labelText: 'Theme'), items: const [DropdownMenuItem(value: 'system', child: Text('System default')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))], onChanged: (value) => setState(() => _theme = value!)),
      const SizedBox(height: 24),
      FilledButton(onPressed: _save, child: const Padding(padding: EdgeInsets.all(12), child: Text('Save changes'))),
    ]),
  );
  Future<void> _save() async { try { await ref.read(profileControllerProvider.notifier).save(UserProfile(id: widget.profile.id, name: _name.text.trim(), email: widget.profile.email, createdAt: widget.profile.createdAt, themeMode: _theme)); if (mounted) Navigator.pop(context); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update profile.'))); } }
}
