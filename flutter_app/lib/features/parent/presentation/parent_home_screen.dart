import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_notifications_screen.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key, required this.me, required this.children});
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> children;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _tab = 0;
  late String _childId;
  late Future<dynamic> _today;
  late Future<dynamic> _unread;
  int _unreadCount = 0;
  String? _unreadError;

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
    _unreadError = null;
    _unread = ApiClient.instance.getUnreadCount().then((value) {
      if (mounted) setState(() {
        _unreadCount = _number(value is Map ? value['count'] : 0);
        _unreadError = null;
      });
      return value;
    }).catchError((Object error) {
      if (mounted) setState(() => _unreadError = errorMessage(error));
      return null;
    });
  }

  Map<String, dynamic> get _child => widget.children.firstWhere((item) => item['id'].toString() == _childId, orElse: () => widget.children.first);

  void _selectTab(int index) => setState(() => _tab = index);

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
        body = ParentAttendanceScreen(children: widget.children, selectedChildId: _childId, onChildSelected: (id) => setState(() => _childId = id));
        break;
      case 2:
        body = ParentNotificationsScreen();
        break;
      case 3:
        body = SettingsScreen(me: widget.me, children: widget.children, onLogout: _logout);
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
        const SizedBox(height: 14),
        if (widget.children.length > 1) ...[
          SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, children: [
            for (var i = 0; i < widget.children.length; i++)
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                label: Text(_childName(widget.children[i])),
                selected: widget.children[i]['id'].toString() == _childId,
                onSelected: (_) => setState(() => _childId = widget.children[i]['id'].toString()),
                selectedColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg,
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
              if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              if (snapshot.hasError) return _inlineError(errorMessage(snapshot.error!));
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
        Row(children: [
          Expanded(child: _actionCard(context, 'Attendance calendar', Icons.calendar_month_outlined, () => _selectTab(1), grade)),
          const SizedBox(width: 10),
          Expanded(child: _actionCard(context, 'Leave requests', Icons.edit_calendar_outlined, () => _selectTab(1), grade)),
        ]),
        const SizedBox(height: 24),
        const _SmallFooter(),
      ]),
    );
  }

  Future<void> _logout() async {
    try {
      await ApiClient.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(error))));
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
IconData _attendanceIcon(String status) => switch (status.toLowerCase()) { 'present' => Icons.check_circle, 'absent' => Icons.cancel, 'late' => Icons.schedule, _ => Icons.info_outline };
Color _attendanceColor(String status) => switch (status.toLowerCase()) { 'present' => AppColors.success, 'absent' => AppColors.danger, 'late' => AppColors.warning, _ => AppColors.muted };
