import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key, required this.children, required this.selectedChildId, required this.onChildSelected});
  final List<Map<String, dynamic>> children;
  final String selectedChildId;
  final ValueChanged<String> onChildSelected;

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  late DateTime _month;
  late Future<List<dynamic>> _data;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _data = _load();
  }

  String get _monthKey => '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  String get _from => '$_monthKey-01';
  String get _to => DateTime(_month.year, _month.month + 1, 0).toIso8601String().split('T').first;

  Future<List<dynamic>> _load() async {
    final api = ApiClient.instance;
    return Future.wait([
      api.getChildAttendance(widget.selectedChildId, _monthKey),
      api.getCalendar(widget.selectedChildId, _from, _to),
      api.getLeaveRequests(widget.selectedChildId),
    ]);
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _createLeave() async {
    final today = DateTime.now();
    final todayIso = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final rangeEnd = DateTime(today.year + 1, today.month, today.day);
    final rangeEndIso = '${rangeEnd.year}-${rangeEnd.month.toString().padLeft(2, '0')}-${rangeEnd.day.toString().padLeft(2, '0')}';
    DateTime earliest = DateTime(today.year, today.month, today.day);
    try {
      final availability = await ApiClient.instance.getWorkingDays(widget.selectedChildId, todayIso, rangeEndIso);
      if (availability is! Map) throw const FormatException('The server returned invalid leave availability data.');
      final date = availability['earliest_start']?.toString();
      if (date != null && date.isNotEmpty) earliest = DateTime.parse(date);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    final reason = TextEditingController();
    DateTime start = earliest;
    DateTime end = start;
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, update) => AlertDialog(
        title: const Text('Request leave'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Earliest leave date: ${_date(earliest)}'),
          const SizedBox(height: 8),
          OutlinedButton.icon(icon: const Icon(Icons.date_range), label: Text('${_date(start)}${start == end ? '' : ' – ${_date(end)}'}'), onPressed: () async {
            final range = await showDateRangePicker(context: context, firstDate: earliest, lastDate: rangeEnd, initialDateRange: DateTimeRange(start: start, end: end));
            if (range != null) update(() { start = range.start; end = range.end; });
          }),
          const SizedBox(height: 10),
          TextField(controller: reason, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Reason')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: AppColors.danger))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (reason.text.trim().isEmpty) { update(() => error = 'Enter a reason for the leave request.'); return; }
            Navigator.pop(dialogContext, true);
          }, child: const Text('Send request')),
        ],
      )),
    );
    if (confirmed != true) { reason.dispose(); return; }
    try {
      await ApiClient.instance.createLeaveRequest(
        widget.selectedChildId,
        startsOn: start.toIso8601String().split('T').first,
        endsOn: end.toIso8601String().split('T').first,
        reason: reason.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request sent.')));
        _reload();
      }
    } catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.toString())));
    } finally {
      reason.dispose();
    }
  }

  Future<void> _withdraw(Map item) async {
    try {
      await ApiClient.instance.withdrawLeaveRequest(widget.selectedChildId, item['id'].toString(), (item['version'] as num?)?.toInt() ?? 1);
      _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.children.indexWhere((child) => child['id'].toString() == widget.selectedChildId);
    final grade = getParentColorGrade(index < 0 ? 0 : index);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : grade.cardBg;
    final fg = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    return RefreshIndicator(onRefresh: () async => _reload(), child: ListView(padding: const EdgeInsets.all(18), children: [
      Text('Attendance', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: fg)),
      const SizedBox(height: 12),
      if (widget.children.length > 1) DropdownButtonFormField<String>(
        value: widget.selectedChildId,
        decoration: const InputDecoration(labelText: 'Child'),
        items: [for (final child in widget.children) DropdownMenuItem(value: child['id'].toString(), child: Text(_name(child)))],
        onChanged: (id) { if (id != null) widget.onChildSelected(id); setState(() => _data = _load()); },
      ),
      const SizedBox(height: 8),
      Row(children: [
        IconButton(onPressed: () => setState(() { _month = DateTime(_month.year, _month.month - 1); _data = _load(); }), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Text('${_monthName(_month.month)} ${_month.year}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: fg))),
        IconButton(onPressed: () => setState(() { _month = DateTime(_month.year, _month.month + 1); _data = _load(); }), icon: const Icon(Icons.chevron_right)),
      ]),
      FutureBuilder<List<dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
          if (snapshot.hasError) return _errorCard(errorMessage(snapshot.error!), () => _reload());
          if (snapshot.data == null || snapshot.data!.length != 3 || snapshot.data![0] is! Map || snapshot.data![1] is! List || snapshot.data![2] is! List) return _errorCard('The server returned invalid attendance data.', () => _reload());
          final attendance = Map<String, dynamic>.from(snapshot.data![0] as Map);
          final events = snapshot.data![1] as List;
          final leaves = snapshot.data![2] as List;
          final monthDays = attendance['month'] is List ? attendance['month'] as List : const [];
          final year = attendance['year'] is Map ? Map<String, dynamic>.from(attendance['year'] as Map) : <String, dynamic>{};
          final percent = year['percent']?.toString();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('School year summary', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(percent == null ? 'Attendance percentage unavailable' : '$percent% present', style: TextStyle(color: dark ? AppColors.darkPrimary : grade.accentText, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('${year['present_days'] ?? '—'} present days / ${year['working_days'] ?? '—'} working days', style: TextStyle(color: muted)),
            ]))),
            Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Days this month', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (monthDays.isEmpty) Text('No attendance days were returned for this month.', style: TextStyle(color: muted))
              else for (final entry in monthDays.whereType<Map>()) _dayTile(entry, fg, muted),
            ]))),
            Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('Leave requests', style: TextStyle(color: fg, fontWeight: FontWeight.w700))), FilledButton.tonalIcon(onPressed: _createLeave, icon: const Icon(Icons.add), label: const Text('Request'))]),
              const SizedBox(height: 6),
              if (leaves.isEmpty) Text('No leave requests have been returned.', style: TextStyle(color: muted))
              else for (final item in leaves.whereType<Map>()) _leaveTile(item, fg, muted),
            ]))),
            if (events.isNotEmpty) Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('School calendar', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final event in events.whereType<Map>()) ListTile(contentPadding: EdgeInsets.zero, title: Text(event['name']?.toString() ?? 'Calendar event', style: TextStyle(color: fg)), subtitle: Text('${event['starts_on'] ?? ''}${event['ends_on'] == event['starts_on'] ? '' : ' – ${event['ends_on'] ?? ''}'}', style: TextStyle(color: muted))),
            ]))),
            const SizedBox(height: 22),
            Center(child: Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1))),
          ]);
        },
      ),
    ]));
  }

  Widget _dayTile(Map day, Color fg, Color muted) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(day['kind']?.toString() == 'holiday' ? Icons.celebration_outlined : Icons.event_available_outlined, size: 20, color: AppColors.primary),
        title: Text(day['date']?.toString() ?? 'Date unavailable', style: TextStyle(color: fg)),
        subtitle: Text([day['kind'], day['holiday_name'], if (day['sessions'] is List) (day['sessions'] as List).join(', ')].where((e) => e != null && e.toString().isNotEmpty).join(' · '), style: TextStyle(color: muted)),
      );

  Widget _leaveTile(Map item, Color fg, Color muted) {
    final status = item['status']?.toString() ?? 'unknown';
    final canWithdraw = status == 'pending' && item['withdrawn_at'] == null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item['reason']?.toString() ?? 'Leave request', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      subtitle: Text('${item['starts_on'] ?? ''} – ${item['ends_on'] ?? ''} · ${_humanize(status)}', style: TextStyle(color: muted)),
      trailing: canWithdraw ? TextButton(onPressed: () => _withdraw(item), child: const Text('Withdraw')) : null,
    );
  }
}

Widget _errorCard(String message, VoidCallback retry) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(message, style: const TextStyle(color: AppColors.danger)), TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
String _name(Map<String, dynamic> child) => child['full_name']?.toString() ?? child['first_name']?.toString() ?? 'Child';
String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _monthName(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];
String _humanize(String value) => value.replaceAll('_', ' ').split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
String errorMessage(Object error) => error.toString();
