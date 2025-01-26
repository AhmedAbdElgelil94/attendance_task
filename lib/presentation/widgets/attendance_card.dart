import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance record;

  const AttendanceCard({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${record.date != null ? DateFormat('MMM d, y').format(record.date!) : 'N/A'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Check In: ${record.checkIn != null ? DateFormat('hh:mm a').format(record.checkIn!) : 'N/A'}',
                ),
                Text(
                  'Check Out: ${record.checkOut != null ? DateFormat('hh:mm a').format(record.checkOut!) : 'N/A'}',
                ),
              ],
            ),
            if (record.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${record.duration!.inHours}h ${record.duration!.inMinutes % 60}m',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 