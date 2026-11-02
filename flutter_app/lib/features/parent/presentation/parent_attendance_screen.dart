import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import 'parent_widgets.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key, required this.api, required this.children});
  final ApiClient api;
  final List<JsonMap> children;

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  String? _studentId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  JsonMap? _attendance;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _studentId = widget.children.first['id']?.toString();
      _load();
    }
  }

  Future<void> _load() async {
    final studentId = _studentId;
    if (studentId == null || studentId.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.api.getChildAttendance(studentId, DateFormat('yyyy-MM').format(_month));
      if (result is! Map ||
          result['year'] is! Map ||
          result['month'] is! List ||
          (result['month'] as List).any((item) => item is! Map) ||
          result['absences'] is! List ||
          (result['absences'] as List).any((item) => item is! Map)) {
        throw const FormatException('The school server returned invalid attendance data.');
      }
      if (mounted) setState(() { _attendance = Map<String, dynamic>.from(result); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _attendance = null; _error = error; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int amount) {
    setState(() { _month = DateTime(_month.year, _month.month + amount); _attendance = null; });
    _load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 28), children: [
          Text('Attendance', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (widget.children.isEmpty)
            const ParentEmptyCard(message: 'No children are linked to this parent account.')
          else ...[
            DropdownButtonFormField<String>(
              value: _studentId,
              decoration: const InputDecoration(labelText: 'Child'),
              items: widget.children.map((child) => DropdownMenuItem(value: child['id']?.toString(), child: Text(child['full_name']?.toString() ?? ''))).toList(),
              onChanged: (value) {
                setState(() { _studentId = value; _attendance = null; });
                _load();
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(child: Text(DateFormat('MMMM yyyy').format(_month), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ]),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              ApiErrorPanel(message: readableError(_error!), onRetry: _load)
            else if (_attendance != null)
              _AttendanceData(data: _attendance!)
            else
              const ParentEmptyCard(message: 'No attendance data was returned for this month.'),
          ],
        ]),
      );
}

class _AttendanceData extends StatelessWidget {
  const _AttendanceData({required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final year = Map<String, dynamic>.from(data['year'] as Map);
    final month = (data['month'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    final absences = (data['absences'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(year['name']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Metric(label: 'Present days', value: year['present_days']?.toString() ?? '—')),
          Expanded(child: _Metric(label: 'Working days', value: year['working_days']?.toString() ?? '—')),
          Expanded(child: _Metric(label: 'Attendance', value: year['percent'] == null ? '—' : '${year['percent']}%')),
        ]),
      ]))),
      const SizedBox(height: 12),
      Text('Month', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      if (month.isEmpty)
        const ParentEmptyCard(message: 'No attendance days were returned for this month.')
      else
        ...month.map((day) {
          final status = day['status']?.toString() ?? day['kind']?.toString() ?? '';
          final holiday = day['holiday_name']?.toString() ?? '';
          final sessions = day['sessions'] is List ? (day['sessions'] as List).join(', ') : '';
          return Card(child: ListTile(
            leading: Icon(status == 'working' ? Icons.check_circle_outline : Icons.event_note_outlined),
            title: Text(apiDate(day['date'])),
            subtitle: Text(holiday.isNotEmpty ? holiday : _title(status)),
            trailing: sessions.isEmpty ? null : Text(sessions, textAlign: TextAlign.end),
          ));
        }),
      if (absences.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Absences', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ...absences.map((absence) => Card(child: ListTile(
          title: Text(absence['reason']?.toString() ?? ''),
          subtitle: Text('${apiDate(absence['starts_on'])} – ${apiDate(absence['ends_on'])}'),
          trailing: Text(_title(absence['status']?.toString() ?? '')),
        ))),
      ],
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]);
}

String _title(String value) => value.split(RegExp(r'[_ -]+')).where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
