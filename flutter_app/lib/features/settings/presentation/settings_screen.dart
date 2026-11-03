import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../profile/presentation/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.me, required this.children, required this.onLogout});
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> children;
  final Future<void> Function() onLogout;

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

  Future<void> _emailChange() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final sent = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Change email'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Current email: ${_user['email'] ?? 'Not available'}'),
        const SizedBox(height: 12),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email address.' : null),
        const SizedBox(height: 10),
        TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Your password'), validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Send link'))],
    ));
    if (sent == true) {
      try {
        await ApiClient.instance.requestEmailChange(email.text, password.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation link sent. Your email changes after you open it.')));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    email.dispose();
    password.dispose();
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Change password'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) => v == null || v.isEmpty ? 'Enter your current password.' : null),
        const SizedBox(height: 8),
        TextFormField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: (v) => v == null || v.length < 10 ? 'Use at least 10 characters.' : null),
        const SizedBox(height: 8),
        TextFormField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'), validator: (v) => v != next.text ? 'Passwords do not match.' : null),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Update'))],
    ));
    if (submitted == true) {
      try {
        await ApiClient.instance.changePassword(current.text, next.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => page));
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
            onTap: () => _push(ProfileScreen(me: widget.me, child: widget.children[i], colorIndex: i)),
          ),
      ]),
      const SizedBox(height: 12),
      _sectionCard('Account', [
        ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('Alert preferences'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(const AlertPreferencesScreen())),
        ListTile(leading: const Icon(Icons.contact_mail_outlined), title: const Text('Contact details'), subtitle: Text(_user['email']?.toString() ?? 'Email unavailable'), trailing: const Icon(Icons.chevron_right), onTap: _emailChange),
        ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Change password'), trailing: const Icon(Icons.chevron_right), onTap: _changePassword),
        ListTile(leading: const Icon(Icons.devices_outlined), title: const Text('Signed-in devices'), trailing: const Icon(Icons.chevron_right), onTap: () => _push(const SignedInDevicesScreen())),
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
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _pageError(snapshot.error.toString(), () => setState(_load));
          if (snapshot.data is! Map || (snapshot.data as Map)['categories'] is! List) return _pageError('The server returned invalid alert settings.', () => setState(_load));
          final categories = (snapshot.data as Map)['categories'] as List;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              if (categories.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('The server returned no alert categories.')),
              for (final item in categories.whereType<Map>()) ...[
                ListTile(title: Text(_humanize(item['category']?.toString() ?? 'Alert')), subtitle: item['locked_on'] == true ? const Text('At least one delivery method must stay on.') : null),
                SwitchListTile(title: const Text('Push'), value: item['push'] == true, onChanged: item['push'] == true && item['email'] != true ? null : (value) => _save(item['category'].toString(), value, item['email'] == true)),
                SwitchListTile(title: const Text('Email'), value: item['email'] == true, onChanged: item['email'] == true && item['push'] != true ? null : (value) => _save(item['category'].toString(), item['push'] == true, value)),
                const Divider(),
              ],
              Text('Push devices: ${snapshot.data['push_devices'] ?? 0}', textAlign: TextAlign.left),
            ]))),
          ]);
        }),
      );
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
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
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
