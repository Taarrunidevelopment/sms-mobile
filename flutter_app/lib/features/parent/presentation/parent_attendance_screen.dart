import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/api_loading_skeleton.dart';
import '../../settings/presentation/account_pages.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key, required this.children, required this.selectedChildId, required this.onChildSelected, this.showCalendarInitially = false});
  final List<Map<String, dynamic>> children;
  final String selectedChildId;
  final ValueChanged<String> onChildSelected;
  final bool showCalendarInitially;

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  late DateTime _month;
  late Future<List<dynamic>> _data;
  DateTime? _selectedDate;
  final GlobalKey _calendarKey = GlobalKey();
  bool _calendarScrollScheduled = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _data = _load();
  }

  @override
  void didUpdateWidget(covariant ParentAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChildId != widget.selectedChildId) {
      _selectedDate = null;
      _data = _load();
    }
  }

  String get _monthKey => '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  String get _from => '$_monthKey-01';
  String get _to => _isoDate(DateTime(_month.year, _month.month + 1, 0));

  Future<List<dynamic>> _load() => Future.wait([
        ApiClient.instance.getChildAttendance(widget.selectedChildId, _monthKey),
        ApiClient.instance.getCalendar(widget.selectedChildId, _from, _to),
        ApiClient.instance.getLeaveRequests(widget.selectedChildId),
        ApiClient.instance.getTodayAttendance(),
      ]);

  void _reload() => setState(() => _data = _load());

  Future<void> _openLeaveRequest() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => LeaveRequestScreen(children: widget.children, selectedChildId: widget.selectedChildId, colorIndex: widget.children.indexWhere((child) => child['id'].toString() == widget.selectedChildId)),
    ));
    if (created == true && mounted) _reload();
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
    final childIndex = widget.children.indexWhere((child) => child['id'].toString() == widget.selectedChildId);
    final grade = getParentColorGrade(childIndex < 0 ? 0 : childIndex);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    final surface = dark ? AppColors.darkSurface : grade.cardBg;
    final selectedChild = widget.children.firstWhere((child) => child['id'].toString() == widget.selectedChildId, orElse: () => widget.children.first);

    return Column(children: [
      Expanded(child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 18), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Attendance', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: fg, letterSpacing: -0.4)),
              Text(_childName(selectedChild), style: TextStyle(color: muted)),
            ])),
            if (widget.children.length > 1) DropdownButton<String>(
              value: widget.selectedChildId,
              underline: const SizedBox.shrink(),
              items: [for (final child in widget.children) DropdownMenuItem(value: child['id'].toString(), child: Text(_childName(child)))],
              onChanged: (id) { if (id != null) { widget.onChildSelected(id); setState(() { _selectedDate = null; _data = _load(); }); } },
            ),
          ]),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'attendance');
              if (snapshot.hasError) return _errorCard(snapshot.error.toString(), _reload);
              if (snapshot.data == null || snapshot.data!.length != 4 || snapshot.data![0] is! Map || snapshot.data![1] is! List || snapshot.data![2] is! List || snapshot.data![3] is! List) {
                return _errorCard('The server returned invalid attendance data.', _reload);
              }
              if (widget.showCalendarInitially && !_calendarScrollScheduled) {
                _calendarScrollScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final target = _calendarKey.currentContext;
                  if (mounted && target != null) {
                    Scrollable.ensureVisible(target, alignment: 0.03, duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
                  }
                });
              }
              final attendance = Map<String, dynamic>.from(snapshot.data![0] as Map);
              final events = (snapshot.data![1] as List).whereType<Map>().toList();
              final leaves = (snapshot.data![2] as List).whereType<Map>().toList();
              final todayRecords = (snapshot.data![3] as List).whereType<Map>().toList();
              final dayData = attendance['month'] is List ? (attendance['month'] as List).whereType<Map>().toList() : <Map>[];
              final absences = attendance['absences'] is List ? (attendance['absences'] as List).whereType<Map>().toList() : <Map>[];
              final year = attendance['year'] is Map ? Map<String, dynamic>.from(attendance['year'] as Map) : <String, dynamic>{};
              final percent = double.tryParse(year['percent']?.toString() ?? '');
              final todayMatches = todayRecords.where((record) => record['student_id']?.toString() == widget.selectedChildId).toList();
              final todayRecord = todayMatches.isEmpty ? null : todayMatches.first;
              final threshold = attendance['threshold']?.toString();
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _yearSummary(year, percent, threshold, surface, fg, muted, grade, dark),
                _calendarCard(dayData, absences, events, todayRecord, surface, fg, muted, grade, dark),
                if (_selectedDate != null) _selectedDayInfo(_selectedDate!, dayData, absences, events, fg, muted, surface),
                Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Leave requests', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (leaves.isEmpty) Text('No leave requests were returned.', style: TextStyle(color: muted))
                  else for (final item in leaves) _leaveTile(item, fg, muted),
                ]))),
                if (events.isNotEmpty) Card(color: surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('School calendar events', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (final event in events) ListTile(contentPadding: EdgeInsets.zero, title: Text(event['name']?.toString() ?? 'Calendar event', style: TextStyle(color: fg)), subtitle: Text('${event['starts_on'] ?? ''}${event['ends_on'] == event['starts_on'] ? '' : ' – ${event['ends_on'] ?? ''}'}', style: TextStyle(color: muted))),
                ]))),
              ]);
            },
          ),
          const SizedBox(height: 8),
          Center(child: Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1))),
        ]),
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _openLeaveRequest, icon: const Icon(Icons.event_available_outlined), label: const Text('Request leave'))),
      )),
    ]);
  }

  Widget _yearSummary(Map<String, dynamic> year, double? percent, String? threshold, Color surface, Color fg, Color muted, ParentColorGrade grade, bool dark) {
    final progress = percent == null ? null : (percent / 100).clamp(0.0, 1.0).toDouble();
    return Card(color: surface, child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
      SizedBox(width: 82, height: 82, child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 7, backgroundColor: dark ? AppColors.darkSunken : grade.innerCardBg, color: dark ? AppColors.darkMintInk : AppColors.successInk)),
        Text(percent == null ? '—' : '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
      ])),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance this year', style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
        if (year['name'] != null) ...[const SizedBox(height: 3), Text(year['name'].toString(), style: TextStyle(color: muted, fontSize: 12))],
        const SizedBox(height: 3),
        Text(threshold == null ? '${year['present_days'] ?? '—'} present / ${year['working_days'] ?? '—'} working days' : 'School minimum $threshold%', style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: dark ? AppColors.darkSunken : grade.innerCardBg, color: dark ? AppColors.darkPrimary : grade.accentBg)),
      ])),
    ])));
  }

  Widget _calendarCard(List<Map> days, List<Map> absences, List<Map> events, Map? todayRecord, Color surface, Color fg, Color muted, ParentColorGrade grade, bool dark) {
    final startOffset = DateTime(_month.year, _month.month, 1).weekday - 1;
    final dayCount = DateTime(_month.year, _month.month + 1, 0).day;
    final daysByDate = {for (final item in days) item['date'].toString(): item};
    final today = DateTime.now();
    final todayStatus = todayRecord?['status']?.toString();
    return Card(key: _calendarKey, color: surface, child: Padding(padding: const EdgeInsets.fromLTRB(12, 9, 12, 14), child: Column(children: [
      Row(children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() { _month = DateTime(_month.year, _month.month - 1); _selectedDate = null; _data = _load(); }), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Text('${_monthName(_month.month)} ${_month.year}', textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w800))),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() { _month = DateTime(_month.year, _month.month + 1); _selectedDate = null; _data = _load(); }), icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 7),
      Row(children: [for (final label in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) Expanded(child: Center(child: Text(label, style: TextStyle(fontSize: 11, color: muted))))]),
      const SizedBox(height: 7),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: startOffset + dayCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1),
        itemBuilder: (context, index) {
          if (index < startOffset) return const SizedBox.shrink();
          final date = DateTime(_month.year, _month.month, index - startOffset + 1);
          final key = _isoDate(date);
          final day = daysByDate[key];
          final absence = _absenceFor(date, absences);
          final event = _eventFor(date, events);
          var kind = absence?['status']?.toString() ?? day?['kind']?.toString() ?? 'not_marked';
          final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
          if (isToday && todayStatus != null) kind = todayStatus;
          else if (absence == null && day?['kind'] == 'working' && date.isBefore(DateTime(today.year, today.month, today.day))) kind = 'present';
          if (day?['kind'] == 'holiday' || event?['kind']?.toString().toLowerCase() == 'holiday') kind = 'holiday';
          final selected = _selectedDate != null && _sameDate(_selectedDate!, date);
          final icon = _dayIcon(kind);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              decoration: BoxDecoration(color: _dayColor(kind, dark, grade), borderRadius: BorderRadius.circular(8), border: Border.all(color: selected || isToday ? (dark ? AppColors.darkPrimary : grade.accentBg) : Colors.transparent, width: selected || isToday ? 1.5 : 0)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${date.day}', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: _dayText(kind, dark, muted))),
                if (icon != null) Icon(icon, size: 11, color: _dayText(kind, dark, muted)),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 11, runSpacing: 7, children: [
        _legend('Absent', 'absent', dark, grade),
        _legend('Leave', 'leave', dark, grade),
        _legend('Holiday', 'holiday', dark, grade),
        _legend('Late (counts as present)', 'late', dark, grade),
        _legend('Present', 'present', dark, grade),
      ]),
    ])));
  }

  Widget _selectedDayInfo(DateTime date, List<Map> days, List<Map> absences, List<Map> events, Color fg, Color muted, Color surface) {
    final absence = _absenceFor(date, absences);
    final event = _eventFor(date, events);
    final dayMatches = days.where((item) => item['date']?.toString() == _isoDate(date)).toList();
    final day = dayMatches.isEmpty ? null : dayMatches.first;
    final details = [absence?['reason'], event?['name'], day?['holiday_name'], if (day?['sessions'] is List) (day?['sessions'] as List).join(', ')].where((value) => value != null && value.toString().isNotEmpty).join(' · ');
    return Card(color: surface, child: ListTile(
      leading: const Icon(Icons.event_note_outlined, color: AppColors.primary),
      title: Text(_dateLabel(date), style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
      subtitle: Text(details.isEmpty ? _humanize(day?['kind']?.toString() ?? 'No attendance detail returned') : details, style: TextStyle(color: muted)),
    ));
  }

  Widget _leaveTile(Map item, Color fg, Color muted) {
    final status = item['status']?.toString() ?? 'unknown';
    final start = item['starts_on']?.toString() ?? 'Date unavailable';
    final end = item['ends_on']?.toString() ?? start;
    final canWithdraw = status == 'pending' || status == 'requested';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_busy_outlined),
      title: Text('$start${end == start ? '' : ' – $end'}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
      subtitle: Text('${_humanize(status)}${item['reason'] == null ? '' : ' · ${item['reason']}'}', style: TextStyle(color: muted)),
      trailing: canWithdraw ? TextButton(onPressed: () => _withdraw(item), child: const Text('Withdraw')) : null,
    );
  }

  Widget _legend(String label, String kind, bool dark, ParentColorGrade grade) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 18, height: 18, decoration: BoxDecoration(color: _dayColor(kind, dark, grade), borderRadius: BorderRadius.circular(5)), child: Icon(_dayIcon(kind) ?? Icons.circle, size: 11, color: _dayText(kind, dark, AppColors.muted))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, color: dark ? AppColors.darkMuted : AppColors.muted)),
      ]);

  Map? _absenceFor(DateTime date, List<Map> absences) {
    for (final item in absences) {
      final start = DateTime.tryParse(item['starts_on']?.toString() ?? '');
      final end = DateTime.tryParse(item['ends_on']?.toString() ?? '');
      if (start != null && end != null && !date.isBefore(start) && !date.isAfter(end)) return item;
    }
    return null;
  }

  Map? _eventFor(DateTime date, List<Map> events) {
    for (final item in events) {
      final start = DateTime.tryParse(item['starts_on']?.toString() ?? '');
      final end = DateTime.tryParse(item['ends_on']?.toString() ?? '');
      if (start != null && end != null && !date.isBefore(start) && !date.isAfter(end)) return item;
    }
    return null;
  }

  Color _dayColor(String kind, bool dark, ParentColorGrade grade) => switch (kind) {
        'absent' || 'late' => dark ? AppColors.darkButter : AppColors.warningBg,
        'leave' => dark ? AppColors.darkSky : AppColors.sky,
        'holiday' || 'weekend' || 'no_school' => dark ? AppColors.darkSky : AppColors.sky,
        'present' => dark ? AppColors.darkMint : AppColors.mint,
        _ => dark ? AppColors.darkSunken : grade.innerCardBg,
      };

  Color _dayText(String kind, bool dark, Color muted) => switch (kind) {
        'absent' || 'late' => dark ? AppColors.darkButterInk : AppColors.warningInk,
        'leave' || 'holiday' || 'weekend' || 'no_school' => dark ? AppColors.darkSkyInk : AppColors.skyInk,
        'present' => dark ? AppColors.darkMintInk : AppColors.mintInk,
        _ => muted,
      };

  IconData? _dayIcon(String kind) => switch (kind) {
        'absent' => Icons.close_rounded,
        'leave' => Icons.beach_access_outlined,
        'holiday' || 'no_school' => Icons.event_available_outlined,
        'late' => Icons.schedule_rounded,
        _ => null,
      };

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];

  String _humanize(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _childName(Map<String, dynamic> child) =>
      child['full_name']?.toString() ?? 'Student';

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year && first.month == second.month && first.day == second.day;

  Widget _errorCard(String message, VoidCallback retry) => Card(
        color: AppColors.dangerBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(message, style: const TextStyle(color: AppColors.dangerInk)),
              TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
}
