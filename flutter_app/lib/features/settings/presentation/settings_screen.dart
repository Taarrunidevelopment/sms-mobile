import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../parent/presentation/parent_widgets.dart';
import '../../profile/presentation/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
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
  Widget build(BuildContext context) {
    final user = asJsonMap(me['user']);
    return ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 28), children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Card(child: ListTile(
        leading: ParentAvatar(name: user['full_name']?.toString() ?? '', radius: 28),
        title: Text(user['full_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(user['phone']?.toString() ?? user['email']?.toString() ?? ''),
      )),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your children', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        if (children.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No children are linked to this parent account.'))
        else
          ...children.asMap().entries.map((entry) {
            final child = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ChildGradeAvatar(name: child['full_name']?.toString() ?? '', imageUrl: child['photo_url']?.toString(), index: entry.key),
              title: Text(child['full_name']?.toString() ?? ''),
              subtitle: Text([child['class_name'], child['section_name']].where((value) => value != null && value.toString().isNotEmpty).join(' ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildProfileScreen(api: api, child: child))),
            );
          }),
      ]))),
      Card(child: Column(children: [
        _SettingsTile(icon: Icons.notifications_active_outlined, title: 'Alert preferences', onTap: () => _open(context, AlertPreferencesScreen(api: api))),
        _SettingsTile(icon: Icons.contact_mail_outlined, title: 'Contact details', onTap: () => _open(context, ContactDetailsScreen(api: api, me: me, children: children))),
        _SettingsTile(icon: Icons.lock_outline, title: 'Change password', onTap: () => _open(context, ChangePasswordScreen(api: api))),
        _SettingsTile(icon: Icons.devices_outlined, title: 'Signed-in devices', onTap: () => _open(context, SignedInDevicesScreen(api: api))),
        _SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              try {
                await onThemeChanged(value.name);
              } catch (error) {
                if (context.mounted) showParentMessage(context, readableError(error));
              }
            },
          ),
        ),
      ])),
      Card(child: _SettingsTile(icon: Icons.logout_rounded, title: 'Sign out', color: Theme.of(context).colorScheme.error, onTap: () async {
        try {
          await onSignOut();
        } catch (error) {
          if (context.mounted) showParentMessage(context, readableError(error));
        }
      })),
    ]);
  }

  void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  JsonMap? _response;
  Object? _error;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final result = await widget.api.getAlertPreferences();
      if (result is! Map || result['categories'] is! List || (result['categories'] as List).any((item) => item is! Map)) {
        throw const FormatException('The school server returned invalid alert preferences.');
      }
      if (mounted) setState(() { _response = Map<String, dynamic>.from(result); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _response = null; _error = error; });
    }
  }

  Future<void> _save(JsonMap category, String channel, bool value) async {
    final name = category['category']?.toString() ?? '';
    final push = channel == 'push' ? value : category['push'] == true;
    final email = channel == 'email' ? value : category['email'] == true;
    if (category['locked_on'] == true && !push && !email) {
      showParentMessage(context, 'At least one alert option must stay on.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.saveAlertCategory(name, push, email);
      await _load();
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Alert preferences')),
        body: _error != null
            ? ListView(padding: const EdgeInsets.all(16), children: [ApiErrorPanel(message: readableError(_error!), onRetry: _load)])
            : _response == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                      Row(children: [const Expanded(child: SizedBox()), SizedBox(width: 68, child: Text('Push', textAlign: TextAlign.center)), SizedBox(width: 68, child: Text('Email', textAlign: TextAlign.center))]),
                      ...( _response!['categories'] as List).map((raw) {
                        final category = Map<String, dynamic>.from(raw as Map);
                        final name = category['category']?.toString() ?? '';
                        final locked = category['locked_on'] == true;
                        final hasEmail = _response!['has_email'] == true;
                        return Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_title(name), style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (locked) Text('At least one must stay on', style: Theme.of(context).textTheme.bodySmall),
                          ])),
                          SizedBox(width: 68, child: Switch(value: category['push'] == true, onChanged: _saving || locked && category['email'] != true ? null : (value) => _save(category, 'push', value))),
                          SizedBox(width: 68, child: Switch(value: category['email'] == true, onChanged: _saving || !hasEmail || locked && category['push'] != true ? null : (value) => _save(category, 'email', value))),
                        ]);
                      }),
                      const SizedBox(height: 10),
                      const ParentInfoCard(message: 'Notices are available in the app. Attendance and fee alerts require push or email to be enabled.'),
                    ]))),
                    if ((_response!['categories'] as List).isEmpty) const ParentEmptyCard(message: 'The school has not configured alert categories.'),
                    Card(child: ListTile(title: const Text('Push devices'), subtitle: Text('${_response!['push_devices'] ?? '—'} device(s) registered'), leading: const Icon(Icons.notifications_active_outlined))),
                  ]),
      );
}

class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key, required this.api, required this.me, required this.children});
  final ApiClient api;
  final JsonMap me;
  final List<JsonMap> children;
  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  JsonMap? _office;
  Object? _officeError;
  @override
  void initState() { super.initState(); _loadOfficeContact(); }
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _loadOfficeContact() async {
    if (widget.children.isEmpty) return;
    try {
      final profile = await widget.api.getChildProfile(widget.children.first['id'].toString());
      if (profile is! Map || profile['office'] is! Map) throw const FormatException('The school server did not return office contact details.');
      if (mounted) setState(() { _office = Map<String, dynamic>.from(profile['office'] as Map); _officeError = null; });
    } catch (error) {
      if (mounted) setState(() => _officeError = error);
    }
  }

  Future<void> _submit() async {
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      showParentMessage(context, 'Enter a valid new email and your password.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.requestEmailChange(_email.text, _password.text);
      if (mounted) {
        showParentMessage(context, 'Confirmation link sent. Your email changes after you open it.');
        _email.clear();
        _password.clear();
      }
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = asJsonMap(widget.me['user']);
    return Scaffold(
      appBar: AppBar(title: const Text('Contact details')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Email', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Text('Current email', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          InputDecorator(decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline)), child: Text(user['email']?.toString() ?? '')),
          const SizedBox(height: 14),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email', prefixIcon: Icon(Icons.alternate_email))),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'Your password', suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility)))),
          const SizedBox(height: 8),
          Text('We ask for your password to confirm it is you.', style: Theme.of(context).textTheme.bodySmall),
        ]))),
        Card(child: ListTile(title: const Text('Phone number'), subtitle: Text(user['phone']?.toString() ?? ''), leading: const Icon(Icons.phone_outlined), trailing: const Icon(Icons.lock_outline))),
        if (_officeError != null)
          ApiErrorPanel(message: readableError(_officeError!), onRetry: _loadOfficeContact)
        else if (_office != null)
          Card(child: ListTile(
            title: const Text('School office'),
            subtitle: Text([_office!['phone']?.toString() ?? '', _office!['email']?.toString() ?? ''].where((value) => value.isNotEmpty).join('\n')),
            leading: const Icon(Icons.support_agent_outlined),
          )),
        const ParentInfoCard(message: 'Phone number changes are handled by the school office.'),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Sending…' : 'Send confirmation link')),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _next.text.length < 10 || _next.text != _confirm.text) {
      showParentMessage(context, 'Enter your current password, use at least 10 characters, and confirm the new password.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.changePassword(_current.text, _next.text);
      if (mounted) { showParentMessage(context, 'Password updated.'); Navigator.pop(context); }
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change password')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _PasswordInput(controller: _current, label: 'Current password', visible: _showCurrent, onToggle: () => setState(() => _showCurrent = !_showCurrent)),
          const SizedBox(height: 14),
          _PasswordInput(controller: _next, label: 'New password', visible: _showNext, onToggle: () => setState(() => _showNext = !_showNext), onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          _PasswordRule(text: 'At least 10 characters', met: _next.text.length >= 10),
          const _PasswordRule(text: 'Not a commonly used or leaked password'),
          const _PasswordRule(text: 'Not too similar to your name or email'),
          const _PasswordRule(text: 'Not used in your last 5 passwords'),
          const SizedBox(height: 14),
          _PasswordInput(controller: _confirm, label: 'Confirm new password', visible: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
        ]),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Updating…' : 'Update password')),
          ),
        ),
      );
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({required this.controller, required this.label, required this.visible, required this.onToggle, this.onChanged});
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, obscureText: !visible, decoration: InputDecoration(labelText: label, suffixIcon: IconButton(onPressed: onToggle, icon: Icon(visible ? Icons.visibility_off : Icons.visibility))));
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.text, this.met});
  final String text;
  final bool? met;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
        Icon(met == true ? Icons.check_circle : Icons.circle_outlined, size: 18, color: met == true ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ]));
}

class SignedInDevicesScreen extends StatefulWidget {
  const SignedInDevicesScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<SignedInDevicesScreen> createState() => _SignedInDevicesScreenState();
}

class _SignedInDevicesScreenState extends State<SignedInDevicesScreen> {
  List<JsonMap>? _sessions;
  Object? _error;
  bool _busy = false;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final result = await widget.api.getSessions();
      if (result is! List || result.any((item) => item is! Map)) throw const FormatException('The school server returned invalid session data.');
      if (mounted) setState(() { _sessions = result.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _sessions = null; _error = error; });
    }
  }

  Future<void> _revoke(JsonMap session) async {
    final id = session['id']?.toString() ?? '';
    if (id.isEmpty || session['current'] == true) return;
    setState(() => _busy = true);
    try { await widget.api.revokeSession(id); await _load(); }
    catch (error) { if (mounted) showParentMessage(context, readableError(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _revokeOthers() async {
    setState(() => _busy = true);
    try { await widget.api.revokeOtherSessions(); await _load(); }
    catch (error) { if (mounted) showParentMessage(context, readableError(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Signed-in devices')),
        body: _error != null
            ? ListView(padding: const EdgeInsets.all(16), children: [ApiErrorPanel(message: readableError(_error!), onRetry: _load)])
            : _sessions == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
                    const ParentInfoCard(message: 'Revoke a device you do not recognize. Devices not used for 14 days are signed out automatically.'),
                    const SizedBox(height: 10),
                    if (_sessions!.isEmpty)
                      const ParentEmptyCard(message: 'No signed-in devices were returned.')
                    else
                      ..._sessions!.map((session) {
                        final current = session['current'] == true;
                        final details = [
                          if (current) 'This device',
                          session['location']?.toString() ?? '',
                          if (session['last_active'] != null) apiTimestamp(session['last_active']),
                        ].where((value) => value.isNotEmpty).join(' · ');
                        return Card(child: ListTile(
                          leading: const Icon(Icons.devices_outlined),
                          title: Text(session['device_label']?.toString() ?? ''),
                          subtitle: Text(details),
                          trailing: current
                              ? const Chip(label: Text('This device'))
                              : OutlinedButton(onPressed: _busy ? null : () => _revoke(session), child: const Text('Revoke')),
                        ));
                      }),
                    if (_sessions!.any((session) => session['current'] != true))
                      OutlinedButton(onPressed: _busy ? null : _revokeOthers, child: const Text('Sign out other devices')),
                  ])),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, this.onTap, this.trailing, this.color});
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        title: Text(title, style: TextStyle(color: color)),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
        onTap: onTap,
      );
}

String _title(String value) => value.split(RegExp(r'[_ -]+')).where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
