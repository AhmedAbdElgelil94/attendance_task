import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';

class AttendanceTable extends StatelessWidget {
  final List<AttendanceRecord> records;

  const AttendanceTable({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    records.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Check In')),
            DataColumn(label: Text('Check Out')),
            DataColumn(label: Text('Duration')),
          ],
          rows: records.map((record) {
            final duration = record.checkOut != null && record.checkIn != null
                ? record.checkOut!.difference(record.checkIn!)
                : null;

            return DataRow(
              cells: [
                DataCell(Text(record.date != null 
                    ? DateFormat('MMM d, y').format(record.date!)
                    : '-')),
                DataCell(Text(record.checkIn != null
                    ? DateFormat('hh:mm a').format(record.checkIn!)
                    : '-')),
                DataCell(Text(record.checkOut != null
                    ? DateFormat('hh:mm a').format(record.checkOut!)
                    : '-')),
                DataCell(Text(duration != null
                    ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                    : '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
} 