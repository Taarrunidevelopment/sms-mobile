import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/api_loading_skeleton.dart';
import 'account_pages.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.me, required this.children, required this.onLogout, required this.onSelectChild});
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> children;
  final Future<void> Function() onLogout;
  final ValueChanged<int> onSelectChild;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _savingTheme = false;

  Map<String, dynamic> get _user => widget.me['user'] is Map ? Map<String, dynamic>.from(widget.me['user'] as Map) : <String, dynamic>{};

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _savingTheme = true);
    try {
      await ApiClient.instance.savePreferences(mode.name);
      ref.read(themeModeProvider.notifier).state = mode;
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grade = getParentColorGrade(0);
    final fg = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    final theme = ref.watch(themeModeProvider);
    final themeValue = theme == ThemeMode.system ? 'system' : theme.name;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 28), children: [
      Text('More', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: fg)),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(_user['full_name']?.toString() ?? ''), style: TextStyle(color: dark ? AppColors.darkPrimary : grade.accentText, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user['full_name'].toString(), style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
          Text((_user['phone'] ?? _user['email']).toString(), style: TextStyle(color: muted)),
        ])),
      ]))),
      const SizedBox(height: 14),
      _sectionCard('Your children', [
        for (var i = 0; i < widget.children.length; i++)
          ListTile(
            leading: CircleAvatar(backgroundColor: dark ? AppColors.darkPrimarySoft : getParentColorGrade(i).subtleBg, child: Text(_initials(_childName(widget.children[i])), style: TextStyle(color: dark ? AppColors.darkPrimary : getParentColorGrade(i).accentText))),
            title: Text(_childName(widget.children[i])),
            subtitle: Text([widget.children[i]['class_name'], widget.children[i]['section_name']].where((e) => e != null).join(' · ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onSelectChild(i),
          ),
      ]),
      const SizedBox(height: 12),
      _sectionCard('Account', [
        ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('Alert preferences'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AlertPreferencesScreen()))),
        ListTile(leading: const Icon(Icons.contact_mail_outlined), title: const Text('Contact details'), subtitle: Text(_user['email']?.toString() ?? 'Email unavailable'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ContactDetailsScreen(me: widget.me, studentId: widget.children.first['id'].toString())))),
        ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Change password'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChangePasswordScreen(user: _user)))),
        ListTile(leading: const Icon(Icons.devices_outlined), title: const Text('Signed-in devices'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SignedInDevicesScreen()))),
      ]),
      const SizedBox(height: 12),
      _sectionCard('Appearance', [
        RadioListTile<String>(value: 'light', groupValue: themeValue, title: const Text('Light theme'), onChanged: _savingTheme ? null : (_) => _setTheme(ThemeMode.light)),
        RadioListTile<String>(value: 'dark', groupValue: themeValue, title: const Text('Dark theme'), onChanged: _savingTheme ? null : (_) => _setTheme(ThemeMode.dark)),
        RadioListTile<String>(value: 'system', groupValue: themeValue, title: const Text('Use device setting'), onChanged: _savingTheme ? null : (_) => _setTheme(ThemeMode.system)),
      ]),
      const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.logout, color: AppColors.danger), title: const Text('Sign out'), onTap: widget.onLogout)),
      const SizedBox(height: 22),
      Center(child: Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1))),
    ]);
  }

  Widget _sectionCard(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 4), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), ...children])));
}

class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({super.key});
  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  late Future<dynamic> _future;
  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = ApiClient.instance.getAlertPreferences();

  Future<void> _save(String category, bool push, bool email) async {
    try {
      await ApiClient.instance.saveAlertCategory(category, push, email);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Alert preferences')),
        body: FutureBuilder<dynamic>(future: _future, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const SingleChildScrollView(padding: EdgeInsets.all(16), child: ApiLoadingSkeleton(variant: 'settings'));
          if (snapshot.hasError) return _pageError(snapshot.error.toString(), () => setState(_load));
          if (snapshot.data is! Map || (snapshot.data as Map)['categories'] is! List) return _pageError('The server returned invalid alert settings.', () => setState(_load));
          final payload = snapshot.data as Map;
          final categories = payload['categories'] as List;
          final muted = Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.muted;
          final dark = Theme.of(context).brightness == Brightness.dark;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Expanded(child: SizedBox()), SizedBox(width: 58, child: Text('Push', textAlign: TextAlign.center, style: TextStyle(color: muted))), SizedBox(width: 58, child: Text('Email', textAlign: TextAlign.center, style: TextStyle(color: muted)))])),
              if (categories.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('The server returned no alert categories.')),
              for (final item in categories.whereType<Map>()) _alertCategoryRow(item, muted),
              const SizedBox(height: 10),
              Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: dark ? AppColors.darkSky : AppColors.sky, borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline), const SizedBox(width: 10), Expanded(child: Text('Alerts always appear in the app under the bell. Attendance and fee alerts also need push or email on, so you never miss an absence or a due date.', style: TextStyle(color: dark ? AppColors.darkSkyInk : AppColors.skyInk)))])),
            ]))),
            const SizedBox(height: 14),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Push on this device', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('Registered devices: ${payload['push_devices'] ?? 0}', style: TextStyle(color: muted)),
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This app can save push preferences, but push delivery requires device registration, which is not available in this Flutter build yet.'))), icon: const Icon(Icons.notifications_active_outlined), label: const Text('Turn on push on this device')),
            ]))),
          ]);
        }),
      );

  Widget _alertCategoryRow(Map item, Color muted) {
    final push = item['push'] == true;
    final email = item['email'] == true;
    final category = item['category']?.toString() ?? '';
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_humanize(category), style: const TextStyle(fontWeight: FontWeight.w700)), if (item['locked_on'] == true) Text('At least one must stay on', style: TextStyle(color: muted, fontSize: 11))])),
      SizedBox(width: 58, child: Switch(value: push, onChanged: push && !email ? null : (value) => _save(category, value, email))),
      SizedBox(width: 58, child: Switch(value: email, onChanged: email && !push ? null : (value) => _save(category, push, value))),
    ]));
  }
}

class SignedInDevicesScreen extends StatefulWidget {
  const SignedInDevicesScreen({super.key});
  @override
  State<SignedInDevicesScreen> createState() => _SignedInDevicesScreenState();
}

class _SignedInDevicesScreenState extends State<SignedInDevicesScreen> {
  late Future<dynamic> _future;
  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = ApiClient.instance.getSessions();
  Future<void> _revoke(String id) async {
    try { await ApiClient.instance.revokeSession(id); if (mounted) setState(_load); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
  Future<void> _revokeOthers() async {
    try { await ApiClient.instance.revokeOtherSessions(); if (mounted) setState(_load); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Signed-in devices')),
        body: FutureBuilder<dynamic>(future: _future, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const SingleChildScrollView(padding: EdgeInsets.all(16), child: ApiLoadingSkeleton(variant: 'settings'));
          if (snapshot.hasError) return _pageError(snapshot.error.toString(), () => setState(_load));
          if (snapshot.data is! List) return _pageError('The server returned invalid session data.', () => setState(_load));
          final sessions = snapshot.data as List;
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Revoke a device you do not recognise. Devices not used for 14 days are signed out automatically.'),
            const SizedBox(height: 12),
            for (final item in sessions.whereType<Map>()) Card(child: ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(item['device_label']?.toString() ?? 'Device'),
              subtitle: Text('${item['current'] == true ? 'This device · ' : ''}${item['location'] ?? 'Location unavailable'} · ${item['last_active'] ?? 'Activity unavailable'}'),
              trailing: item['current'] == true ? const Chip(label: Text('This device')) : TextButton(onPressed: item['id'] == null ? null : () => _revoke(item['id'].toString()), child: const Text('Revoke')),
            )),
            if (sessions.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('The server returned no active sessions.'))),
            OutlinedButton.icon(onPressed: _revokeOthers, icon: const Icon(Icons.logout), label: const Text('Sign out other devices')),
          ]);
        }),
      );
}

Widget _pageError(String message, VoidCallback retry) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)), TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
String _initials(String value) => value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
String _childName(Map<String, dynamic> child) => child['full_name'].toString();
String _humanize(String value) => value.replaceAll('_', ' ').split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
