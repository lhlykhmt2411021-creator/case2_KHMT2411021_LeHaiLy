import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    required this.taskService,
    this.task,
  });

  final TaskService taskService;
  final Task? task;

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.task?.description ?? '');

  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late DateTime? _startDate = widget.task?.startDate;
  late DateTime? _dueDate = widget.task?.dueDate;

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
      if (_dueDate != null && _dueDate!.isBefore(picked)) {
        _dueDate = picked;
      }
    });
  }

  Future<void> _pickDueDate() async {
    final DateTime firstDate = _startDate ?? DateTime(2000);
    final DateTime now = DateTime.now();
    DateTime initialDate = _dueDate ?? _startDate ?? now;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: 'Chọn hạn hoàn thành',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String? dateError = Validators.dateRange(_startDate, _dueDate);
    if (dateError != null) {
      _showMessage(dateError);
      return;
    }

    setState(() => _saving = true);

    try {
      final String title = _titleController.text.trim();
      final String description = _descriptionController.text.trim();

      if (widget.isEditing) {
        await widget.taskService.updateTask(
          widget.task!.id,
          title: title,
          description: description,
          priority: _priority,
          startDate: _startDate,
          dueDate: _dueDate,
        );
      } else {
        await widget.taskService.createTask(
          title: title,
          description: description,
          priority: _priority,
          startDate: _startDate,
          dueDate: _dueDate,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.taskTitle,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Mức ưu tiên',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskPriority.values
                      .map(
                        (TaskPriority priority) => DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Text(priority.label),
                        ),
                      )
                      .toList(),
                  onChanged: (TaskPriority? value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _DateField(
                  label: 'Ngày bắt đầu',
                  value: DateFormatter.format(_startDate),
                  onPick: _pickStartDate,
                  onClear: _startDate == null
                      ? null
                      : () => setState(() => _startDate = null),
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: 'Hạn hoàn thành',
                  value: DateFormatter.format(_dueDate),
                  onPick: _pickDueDate,
                  onClear: _dueDate == null
                      ? null
                      : () => setState(() => _dueDate = null),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Lưu thay đổi' : 'Tạo công việc'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (onClear != null)
                IconButton(
                  tooltip: 'Bỏ chọn ngày',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
              IconButton(
                tooltip: 'Chọn ngày',
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ],
          ),
        ),
        child: Text(value),
      ),
    );
  }
}
