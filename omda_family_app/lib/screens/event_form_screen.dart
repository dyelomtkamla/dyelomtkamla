import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/event_type.dart';
import '../models/family_event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';

/// إضافة مناسبة جديدة أو تعديل مناسبة موجودة.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, required this.me, this.existing});

  final AppUser me;
  final FamilyEvent? existing;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  late EventType _type = widget.existing?.type ?? EventType.wedding;
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _description = TextEditingController(text: widget.existing?.description);
  late DateTime? _date = widget.existing?.date;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now.add(const Duration(days: 1));
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? DateTime(now.year, 1, 1, 20)),
    );
    if (time == null) return;
    setState(() =>
        _date = DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اختر موعد المناسبة')));
      return;
    }
    setState(() => _saving = true);
    final event = FamilyEvent(
      id: widget.existing?.id ?? '',
      type: _type,
      title: _title.text.trim(),
      location: _location.text.trim(),
      description: _description.text.trim(),
      date: _date!,
      createdBy: widget.existing?.createdBy ?? widget.me.uid,
      createdByName: widget.existing?.createdByName ?? widget.me.name,
    );
    try {
      if (_editing) {
        await EventService.instance.update(event);
      } else {
        await EventService.instance.create(event);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر الحفظ، حاول مرة أخرى')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'تعديل المناسبة' : 'مناسبة جديدة')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('نوع المناسبة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in EventType.values)
                    ChoiceChip(
                      avatar: Icon(t.icon, size: 18, color: t.color),
                      label: Text(t.label),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'عنوان المناسبة',
                  hintText: _hintFor(_type),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'اكتب عنواناً للمناسبة' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                leading: const Icon(Icons.calendar_month),
                title: Text(_date == null ? 'اختر اليوم والساعة' : formatEventDate(_date!)),
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'المكان',
                  hintText: 'مثال: قاعة ...، أو بيت الحاج ...',
                  prefixIcon: Icon(Icons.place),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_editing ? 'حفظ التعديلات' : 'نشر المناسبة للعائلة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hintFor(EventType t) => switch (t) {
        EventType.wedding => 'مثال: فرح محمد العمدة',
        EventType.engagement => 'مثال: خطوبة أحمد العمدة',
        EventType.condolence => 'مثال: عزاء المرحوم الحاج ...',
        EventType.birth => 'مثال: عقيقة المولود ...',
        EventType.other => 'مثال: تجمع العائلة في العيد',
      };
}
