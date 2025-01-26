import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService =
      GetIt.I<NotificationService>();
  TimeOfDay? _reminderTime;
  bool _isReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final time = await _notificationService.getReminderTime();
    final enabled = await _notificationService.isReminderEnabled();
    setState(() {
      _reminderTime = time;
      _isReminderEnabled = enabled;
    });
  }

  Future<void> _updateReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Select Reminder Time',
      cancelText: 'CANCEL',
      confirmText: 'SET',
      hourLabelText: 'Hour',
      minuteLabelText: 'Minute',
    );

    if (picked != null) {
      await _notificationService.updateReminderTime(picked);
      setState(() {
        _reminderTime = picked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder time updated')),
        );
      }
    }
  }

  Future<void> _toggleReminder(bool value) async {
    await _notificationService.setReminderEnabled(value);
    setState(() {
      _isReminderEnabled = value;
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Daily Reminder'),
            subtitle: const Text('Get notified to mark your attendance'),
            value: _isReminderEnabled,
            onChanged: _toggleReminder,
          ),
          if (_isReminderEnabled) ...[
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(
                _reminderTime != null
                    ? _formatTimeOfDay(_reminderTime!)
                    : '8:00 AM',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _updateReminderTime,
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Reminder will notify you daily at the specified time to mark your attendance.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
