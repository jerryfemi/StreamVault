import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/remote_config.dart';
import '../../../providers/providers.dart';

class CustomEpgDialog extends ConsumerStatefulWidget {
  final String channelId;

  const CustomEpgDialog({super.key, required this.channelId});

  @override
  ConsumerState<CustomEpgDialog> createState() => _CustomEpgDialogState();
}

class _CustomEpgDialogState extends ConsumerState<CustomEpgDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  static const List<String> _tournaments = [
    'UEFA Champions League',
    'Premier League',
    'La Liga',
    'Serie A',
    'Bundesliga',
    'Ligue 1',
    'UEFA Europa League',
    'FA Cup',
    'Copa del Rey',
    'Carabao Cup',
    'FIFA World Cup',
    'UEFA Euros',
    'Copa América',
    'Africa Cup of Nations',
    'MLS',
    'Saudi Pro League',
    'Club Friendly',
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(adminCustomEpgProvider)[widget.channelId];
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');

    final now = DateTime.now();
    _startTime = existing != null
        ? TimeOfDay.fromDateTime(existing.start)
        : TimeOfDay.fromDateTime(now);

    _endTime = existing != null
        ? TimeOfDay.fromDateTime(existing.end)
        : TimeOfDay.fromDateTime(now.add(const Duration(hours: 2)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descController.text.trim();

    final now = DateTime.now();

    // We assume the broadcast is today.
    // If the end time is before the start time, we assume it spans past midnight.
    var start = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    var end = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final customEpg = CustomEpg(
      title: title,
      start: start,
      end: end,
      description: description,
    );
    ref
        .read(adminCustomEpgProvider.notifier)
        .setCustomEpg(widget.channelId, customEpg);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(adminCustomEpgProvider.notifier).removeCustomEpg(widget.channelId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit Custom EPG',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Match Title / Programme',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'League / Tournament (Description)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tournaments.length,
              itemBuilder: (context, index) {
                final item = _tournaments[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(item),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      setState(() {
                        _descController.text = item;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Start Time',
                  time: _startTime,
                  onTap: () => _selectTime(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeButton(
                  label: 'End Time',
                  time: _endTime,
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: _clear,
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
