import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/api_loading_skeleton.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/presentation/account_pages.dart';
import 'parent_attendance_screen.dart';
import 'parent_notifications_screen.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key, required this.me, required this.children});
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> children;

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _tab = 0;
  late String _childId;
  String? _moreChildId;
  late Future<dynamic> _today;
  late Future<dynamic> _calendar;
  late Future<dynamic> _unread;
  int _unreadCount = 0;
  String? _unreadError;
  bool _dismissAlertPrompt = false;

  @override
  void initState() {
    super.initState();
    _childId = widget.children.first['id'].toString();
    final preferences = widget.me['preferences'];
    final preferredTheme = preferences is Map ? preferences['theme']?.toString() : null;
    ref.read(themeModeProvider.notifier).state = switch (preferredTheme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    _refresh();
  }

  void _refresh() {
    _today = ApiClient.instance.getTodayAttendance();
    _calendar = _loadCalendar();
    _loadUnread();
  }

  Future<dynamic> _loadCalendar() {
    final today = DateTime.now();
    final from = _dateKey(today);
    final to = _dateKey(today.add(const Duration(days: 90)));
    return ApiClient.instance.getCalendar(_childId, from, to);
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  void _loadUnread() {
    _unreadError = null;
    _unread = ApiClient.instance.getUnreadCount().then((value) {
      if (mounted) setState(() {
        _unreadCount = _number(value is Map ? value['count'] : 0);
        _unreadError = null;
      });
      return value;
    }).catchError((Object error) {
      if (mounted) setState(() => _unreadError = _errorMessage(error));
      return null;
    });
  }

  Map<String, dynamic> get _child => widget.children.firstWhere((item) => item['id'].toString() == _childId, orElse: () => widget.children.first);

  void _selectTab(int index) => setState(() => _tab = index);

  void _refreshUnreadCount() {
    if (mounted) setState(_loadUnread);
  }

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(me: widget.me, child: _child, colorIndex: widget.children.indexOf(_child))));
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.me['school'] is Map ? Map<String, dynamic>.from(widget.me['school'] as Map) : <String, dynamic>{};
    final user = widget.me['user'] is Map ? Map<String, dynamic>.from(widget.me['user'] as Map) : <String, dynamic>{};
    final shortName = school['short_name']?.toString();
    final schoolName = shortName == null || shortName.isEmpty ? school['name'].toString() : shortName;
    final userName = user['full_name'].toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grade = getParentColorGrade(widget.children.indexOf(_child));
    final unreadFuture = _unread;

    Widget body;
    switch (_tab) {
      case 1:
        body = ParentAttendanceScreen(children: widget.children, selectedChildId: _childId, onChildSelected: (id) => setState(() {
          _childId = id;
          _calendar = _loadCalendar();
        }));
        break;
      case 2:
        body = ParentNotificationsScreen(onUnreadCountChanged: _refreshUnreadCount);
        break;
      case 3:
        final childIndex = widget.children.indexWhere((child) => child['id'].toString() == _moreChildId);
        body = childIndex >= 0
            ? ProfileScreen(me: widget.me, child: widget.children[childIndex], colorIndex: childIndex, embedded: true, onBack: () => setState(() => _moreChildId = null))
            : SettingsScreen(me: widget.me, children: widget.children, onLogout: _logout, onSelectChild: (index) => setState(() => _moreChildId = widget.children[index]['id'].toString()));
        break;
      default:
        body = _homeBody(grade);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : grade.screenBg,
      appBar: AppHeader(
        schoolName: schoolName,
        userName: userName,
        unreadCount: _unreadCount,
        hasUnreadError: _unreadError != null,
        onOpenNotifications: () => _selectTab(2),
        onOpenProfile: () => _selectTab(3),
      ),
      body: _unreadError == null || _tab == 0
          ? body
          : Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _inlineError(_unreadError!)), Expanded(child: body)]),
      bottomNavigationBar: FutureBuilder<dynamic>(
        future: unreadFuture,
        builder: (context, snapshot) {
          final unreadCount = snapshot.hasError ? 0 : _number(snapshot.data is Map ? (snapshot.data as Map)['count'] : 0);
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _selectTab,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              const NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available_rounded), label: 'Attendance'),
              NavigationDestination(icon: Badge(isLabelVisible: snapshot.hasError || _unreadError != null || unreadCount > 0, label: Text(snapshot.hasError || _unreadError != null ? '!' : unreadCount > 9 ? '9+' : '$unreadCount'), child: const Icon(Icons.campaign_outlined)), selectedIcon: const Icon(Icons.campaign_rounded), label: 'Notices'),
              const NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_rounded), label: 'More'),
            ],
          );
        },
      ),
    );
  }

  Widget _homeBody(ParentColorGrade grade) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : grade.cardBg;
    final text = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    return RefreshIndicator(
      onRefresh: () async => setState(_refresh),
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 32), children: [
        Text('Home', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text)),
        if (_unreadError != null) ...[const SizedBox(height: 12), _inlineError(_unreadError!)],
        if (!_dismissAlertPrompt) ...[
          const SizedBox(height: 12),
          Card(color: dark ? AppColors.darkPrimarySoft : AppColors.primarySoft, child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 6, 12), child: Row(children: [
            Icon(Icons.notifications_active_outlined, color: dark ? AppColors.darkPrimary : AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('Turn on alerts to know when your child is absent', style: TextStyle(color: dark ? AppColors.darkInk : grade.textMain, fontWeight: FontWeight.w700))),
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AlertPreferencesScreen())), child: const Text('Turn on')),
            IconButton(tooltip: 'Dismiss', onPressed: () => setState(() => _dismissAlertPrompt = true), icon: const Icon(Icons.close_rounded)),
          ]))),
        ],
        const SizedBox(height: 14),
        if (widget.children.length > 1) ...[
          SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, children: [
            for (var i = 0; i < widget.children.length; i++)
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                label: Text(_childName(widget.children[i])),
                selected: widget.children[i]['id'].toString() == _childId,
                onSelected: (_) => setState(() {
                  _childId = widget.children[i]['id'].toString();
                  _calendar = _loadCalendar();
                }),
                selectedColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg,
                labelStyle: TextStyle(color: dark ? AppColors.darkInk : grade.textMain, fontWeight: FontWeight.w700),
              )),
          ])),
          const SizedBox(height: 14),
        ],
        Card(color: surface, child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openProfile,
          child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(_childName(_child)), style: TextStyle(color: dark ? AppColors.darkPrimary : grade.accentText, fontWeight: FontWeight.w800))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_childName(_child), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
              Text(_sectionLabel(_child), style: TextStyle(color: muted)),
            ])),
            Icon(Icons.chevron_right, color: muted),
          ])),
        )),
        const SizedBox(height: 12),
        Card(color: surface, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's attendance", style: TextStyle(fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 12),
          FutureBuilder<dynamic>(
            future: _today,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'inline');
              if (snapshot.hasError) return _inlineError(_errorMessage(snapshot.error!));
              if (snapshot.data is! List) return _inlineError('The server returned invalid attendance data.');
              final matches = (snapshot.data as List).where((entry) => entry is Map && entry['student_id'].toString() == _childId).toList();
              if (matches.isEmpty) return Text('No attendance record is available for today.', style: TextStyle(color: muted));
              final attendance = Map<String, dynamic>.from(matches.first as Map);
              final status = attendance['status']?.toString() ?? 'unknown';
              return Row(children: [
                Icon(_attendanceIcon(status), color: _attendanceColor(status)),
                const SizedBox(width: 8),
                Expanded(child: Text(_humanize(status), style: TextStyle(fontWeight: FontWeight.w700, color: text))),
                if (attendance['holiday_name'] != null) Text(attendance['holiday_name'].toString(), style: TextStyle(color: muted)),
              ]);
            },
          ),
        ]))),
        const SizedBox(height: 12),
        _schoolCalendarCard(text, muted, surface, dark, grade),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _actionCard(context, 'Leave requests', Icons.edit_calendar_outlined, () => _selectTab(1), grade)),
        ]),
        const SizedBox(height: 24),
        const _SmallFooter(),
      ]),
    );
  }

  Widget _schoolCalendarCard(Color text, Color muted, Color surface, bool dark, ParentColorGrade grade) => Card(
        color: surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('School calendar', style: TextStyle(fontWeight: FontWeight.w800, color: text))),
              TextButton(onPressed: () => _selectTab(1), child: const Text('Attendance')),
            ]),
            FutureBuilder<dynamic>(
              future: _calendar,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'inline');
                if (snapshot.hasError) return _calendarError(_errorMessage(snapshot.error!));
                if (snapshot.data is! List) return _calendarError('The school calendar returned invalid data.');
                final today = DateTime.now();
                final events = (snapshot.data as List)
                    .whereType<Map>()
                    .where((event) {
                      final start = DateTime.tryParse(event['starts_on']?.toString() ?? '');
                      final end = DateTime.tryParse(event['ends_on']?.toString() ?? '');
                      return start != null && (end == null || !end.isBefore(DateTime(today.year, today.month, today.day)));
                    })
                    .toList()
                  ..sort((a, b) => (a['starts_on']?.toString() ?? '').compareTo(b['starts_on']?.toString() ?? ''));
                if (events.isEmpty) return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('No upcoming school calendar events were returned.', style: TextStyle(color: muted)));
                return Column(children: [
                  for (final event in events.take(3)) _calendarEventTile(event, text, muted, dark, grade),
                ]);
              },
            ),
          ]),
        ),
      );

  Widget _calendarEventTile(Map event, Color text, Color muted, bool dark, ParentColorGrade grade) {
    final start = DateTime.tryParse(event['starts_on']?.toString() ?? '');
    final end = DateTime.tryParse(event['ends_on']?.toString() ?? '');
    final dateText = start == null
        ? 'Date unavailable'
        : end == null || end.year == start.year && end.month == start.month && end.day == start.day
            ? _calendarDate(start)
            : '${_calendarDate(start)} – ${_calendarDate(end)}';
    final kind = event['kind']?.toString() ?? 'Event';
    final reopensOn = event['reopens_on']?.toString();
    final description = event['description']?.toString().trim() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg,
        child: Icon(kind.toLowerCase().contains('holiday') ? Icons.beach_access_outlined : Icons.event_note_outlined, size: 19, color: dark ? AppColors.darkPrimary : grade.accentText),
      ),
      title: Text(event['name']?.toString() ?? 'School event', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.w700)),
      subtitle: Text('$dateText${description.isEmpty ? '' : '\n$description'}${reopensOn == null || reopensOn.isEmpty ? '' : '\nSchool reopens ${_calendarDate(DateTime.tryParse(reopensOn) ?? DateTime.now())}'}', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, height: 1.35)),
      isThreeLine: description.isNotEmpty || reopensOn != null && reopensOn.isNotEmpty,
    );
  }

  String _calendarDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _calendarError(String message) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _inlineError(message),
        TextButton.icon(onPressed: () => setState(() => _calendar = _loadCalendar()), icon: const Icon(Icons.refresh), label: const Text('Retry calendar')),
      ]);

  Future<void> _logout() async {
    try {
      await ApiClient.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }
}

class _SmallFooter extends StatelessWidget {
  const _SmallFooter();
  @override
  Widget build(BuildContext context) => Center(child: Text('www.taarro.com', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.muted, fontSize: 11, letterSpacing: 1.1)));
}

Widget _actionCard(BuildContext context, String title, IconData icon, VoidCallback onTap, ParentColorGrade grade) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return Card(color: dark ? AppColors.darkSurface : grade.cardBg, child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: dark ? AppColors.darkPrimary : grade.accentText),
      const SizedBox(height: 12),
      Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: dark ? AppColors.darkInk : grade.textMain)),
    ])),
  ));
}

Widget _inlineError(String message) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: const TextStyle(color: AppColors.dangerInk)),
    );

String _childName(Map<String, dynamic> child) => child['full_name'].toString();
String _sectionLabel(Map<String, dynamic> child) => [child['class_name'], child['section_name']].where((e) => e != null && e.toString().isNotEmpty).join(' · ');
String _initials(String value) => value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
int _number(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
String _humanize(String value) => value.replaceAll('_', ' ').split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
String _errorMessage(Object error) => error.toString();
IconData _attendanceIcon(String status) => switch (status.toLowerCase()) { 'present' => Icons.check_circle, 'absent' => Icons.cancel, 'late' => Icons.schedule, _ => Icons.info_outline };
Color _attendanceColor(String status) => switch (status.toLowerCase()) { 'present' => AppColors.success, 'absent' => AppColors.danger, 'late' => AppColors.warning, _ => AppColors.muted };
