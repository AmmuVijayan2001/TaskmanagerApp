import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task.dart';
import 'task_providers.dart';

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({super.key, this.task});
  final Task? task;
  @override ConsumerState<TaskEditor> createState() => _TaskEditorState();
}
class _TaskEditorState extends ConsumerState<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late TaskPriority _priority;
  late TaskCategory _category;
  DateTime? _dueDate;
  @override void initState() { super.initState(); _title = TextEditingController(text: widget.task?.title); _description = TextEditingController(text: widget.task?.description); _priority = widget.task?.priority ?? TaskPriority.medium; _category = widget.task?.category ?? TaskCategory.work; _dueDate = widget.task?.dueDate; }
  @override void dispose() { _title.dispose(); _description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.task == null ? 'New task' : 'Edit task')),
    body: SafeArea(child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: _title, autofocus: true, decoration: const InputDecoration(labelText: 'Title'), validator: (value) => value == null || value.trim().isEmpty ? 'A title is required.' : null),
      const SizedBox(height: 16), TextFormField(controller: _description, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Description (optional)')),
      const SizedBox(height: 16), DropdownButtonFormField(value: _priority, decoration: const InputDecoration(labelText: 'Priority'), items: TaskPriority.values.map((item) => DropdownMenuItem(value: item, child: Text(item.name))).toList(), onChanged: (value) => setState(() => _priority = value!)),
      const SizedBox(height: 16), DropdownButtonFormField(value: _category, decoration: const InputDecoration(labelText: 'Category'), items: TaskCategory.values.map((item) => DropdownMenuItem(value: item, child: Text(item.name))).toList(), onChanged: (value) => setState(() => _category = value!)),
      const SizedBox(height: 16), ListTile(contentPadding: EdgeInsets.zero, title: Text(_dueDate == null ? 'No due date' : 'Due: ${_dueDate!.toLocal().toString().substring(0, 10)}'), trailing: const Icon(Icons.calendar_today_outlined), onTap: () async { final selected = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100), initialDate: _dueDate ?? DateTime.now()); if (selected != null) setState(() => _dueDate = selected); }),
      const SizedBox(height: 24), FilledButton(onPressed: _save, child: const Padding(padding: EdgeInsets.all(12), child: Text('Save task'))),
    ]))),
  );
  Future<void> _save() async { if (!_form.currentState!.validate()) return; try { await ref.read(tasksProvider.notifier).save(existing: widget.task, title: _title.text.trim(), description: _description.text.trim().isEmpty ? null : _description.text.trim(), priority: _priority, category: _category, dueDate: _dueDate); if (mounted) Navigator.pop(context); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save task.'))); } }
}
