import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import 'parent_attendance_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_widgets.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({
    super.key,
    required this.api,
    required this.me,
    required this.children,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onSignOut,
  });

  final ApiClient api;
  final JsonMap me;
  final List<JsonMap> children;
  final ThemeMode themeMode;
  final Future<void> Function(String) onThemeChanged;
  final Future<void> Function() onSignOut;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final school = asJsonMap(widget.me['school']);
    final schoolName = school['short_name']?.toString().trim().isNotEmpty == true
        ? school['short_name'].toString()
        : school['name']?.toString() ?? '';
    final children = widget.children;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(initials(schoolName), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(schoolName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const Text('Parent app', style: TextStyle(fontSize: 11)),
          ])),
        ]),
        actions: [
          IconButton(tooltip: 'Notices', onPressed: () => setState(() => _selectedTab = 2), icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: [
        _ParentDashboard(api: widget.api, me: widget.me, children: children),
        ParentAttendanceScreen(api: widget.api, children: children),
        ParentNotificationsScreen(api: widget.api),
        SettingsScreen(
          api: widget.api,
          me: widget.me,
          children: children,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          onSignOut: widget.onSignOut,
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_open_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class _ParentDashboard extends StatefulWidget {
  const _ParentDashboard({required this.api, required this.me, required this.children});
  final ApiClient api;
  final JsonMap me;
  final List<JsonMap> children;

  @override
  State<_ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<_ParentDashboard> {
  List<JsonMap>? _today;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.api.getTodayAttendance();
      if (result is! List || result.any((item) => item is! Map)) {
        throw const FormatException('The school server returned an invalid attendance response.');
      }
      if (mounted) setState(() {
        _today = result.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false);
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() { _error = error; _today = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = asJsonMap(widget.me['user'])['full_name']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 28), children: [
        Text(userName.isEmpty ? 'Home' : 'Welcome, ${userName.split(' ').first}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(DateTime.now().toLocal().toString().split(' ').first, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_error != null)
          ApiErrorPanel(message: readableError(_error!), onRetry: _load)
        else if (_today == null)
          const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
        else if (widget.children.isEmpty)
          const ParentEmptyCard(message: 'No children are linked to this parent account.')
        else
          ...widget.children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            final id = child['id']?.toString() ?? '';
            final attendanceRows = _today!.where((item) => item['student_id']?.toString() == id);
            final today = attendanceRows.isEmpty ? null : attendanceRows.first;
            final grade = getParentColorGrade(index);
            final cardColor = isDark ? AppColors.darkSurface : grade.cardBg;
            final cardBorder = isDark ? AppColors.darkBorder : grade.cardBorder;
            final mainInk = isDark ? AppColors.darkInk : grade.textMain;
            final muted = isDark ? AppColors.darkMuted : grade.textMuted;
            final status = today?['status']?.toString() ?? '';
            final classLabel = [child['class_name'], child['section_name']]
                .where((value) => value != null && value.toString().trim().isNotEmpty)
                .join(' ');
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: cardBorder)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildProfileScreen(api: widget.api, child: child))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      ChildGradeAvatar(name: child['full_name']?.toString() ?? '', imageUrl: child['photo_url']?.toString(), index: index),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(child['full_name']?.toString() ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: mainInk)),
                        Text(classLabel, style: TextStyle(color: muted)),
                      ])),
                      Icon(Icons.chevron_right, color: muted),
                    ]),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: cardBorder),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.today_outlined, size: 19, color: muted),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Today's attendance", style: TextStyle(color: muted))),
                      Text(status.isEmpty ? '—' : _title(status), style: TextStyle(fontWeight: FontWeight.w800, color: mainInk)),
                    ]),
                    if (today?['holiday_name'] != null && today!['holiday_name'].toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 7), child: Text(today['holiday_name'].toString(), style: TextStyle(color: muted))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _QuickAction(icon: Icons.person_outline, label: 'Profile', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildProfileScreen(api: widget.api, child: child)))),
                      _QuickAction(icon: Icons.event_note_outlined, label: 'Leave', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveRequestsScreen(api: widget.api, child: child)))),
                      _QuickAction(icon: Icons.calendar_month_outlined, label: 'Calendar', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildCalendarScreen(api: widget.api, child: child)))),
                    ]),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 17), label: Text(label), onPressed: onPressed);
}

String _title(String value) => value.split(RegExp(r'[_ -]+')).where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
