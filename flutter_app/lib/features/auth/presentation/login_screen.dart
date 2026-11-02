import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onSignedIn});
  final ApiClient api;
  final Future<void> Function(JsonMap, List<JsonMap>) onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  JsonMap? _branding;
  Object? _error;
  bool _busy = false;
  bool _showPassword = false;
  bool _loadingBranding = true;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadBranding() async {
    setState(() { _loadingBranding = true; _error = null; });
    try {
      final result = await widget.api.fetchBranding();
      if (result is! Map) throw const FormatException('The school server returned invalid branding data.');
      if (mounted) setState(() => _branding = Map<String, dynamic>.from(result));
    } catch (error) {
      if (mounted) setState(() { _branding = null; _error = error; });
    } finally {
      if (mounted) setState(() => _loadingBranding = false);
    }
  }

  Future<void> _submit() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email or phone number and password.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.api.fetchCsrf();
      final result = await widget.api.login(_identifier.text.trim(), _password.text, remember: true);
      final response = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
      final status = response['status']?.toString();
      if (status == 'two_factor_required') {
        final code = await _askCode('Two-step verification', 'Enter a code from your authenticator app or a recovery code.');
        if (code == null) return;
        await widget.api.verifyTwoFactor(code);
      } else if (status == 'two_factor_setup_required') {
        final setup = await widget.api.setupTwoFactor();
        if (setup is! Map) throw const FormatException('The school server returned invalid two-step setup data.');
        final manualKey = setup['manual_key']?.toString() ?? '';
        final code = await _askCode('Set up two-step verification', 'Add this key to your authenticator app, then enter its code.\n\n$manualKey');
        if (code == null) return;
        final confirmation = await widget.api.confirmTwoFactorSetup(code);
        if (confirmation is Map && confirmation['recovery_codes'] is List && mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Save recovery codes'),
              content: SelectableText((confirmation['recovery_codes'] as List).join('\n')),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
            ),
          );
        }
      } else if (status != 'signed_in') {
        throw const FormatException('The school server returned an unrecognized sign-in response.');
      }

      final meResult = await widget.api.getMe();
      if (meResult is! Map) throw const FormatException('The school server returned invalid account data.');
      final me = Map<String, dynamic>.from(meResult);
      if (me['school'] is! Map || me['user'] is! Map || me['preferences'] is! Map) {
        throw const FormatException('The school server returned incomplete account data.');
      }
      if (!(me['areas'] is List && (me['areas'] as List).contains('parent'))) {
        try {
          await widget.api.logout();
        } catch (logoutError) {
          await widget.api.clearSession();
          throw logoutError;
        }
        throw const ApiProblemException(title: 'This account does not have parent portal access.', type: 'staff-only', status: 403);
      }
      final childResult = await widget.api.getChildren();
      if (childResult is! List) throw const FormatException('The school server returned an invalid child list.');
      final children = childResult.map((child) {
        if (child is! Map) throw const FormatException('The school server returned an invalid child record.');
        final record = Map<String, dynamic>.from(child);
        if (record['id'] == null || record['full_name'] == null) throw const FormatException('The school server returned an incomplete child record.');
        return record;
      }).toList(growable: false);
      await widget.onSignedIn(me, children);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askCode(String title, String message) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          const SizedBox(height: 14),
          TextField(controller: input, autofocus: true, decoration: const InputDecoration(labelText: 'Verification code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, input.text.trim()), child: const Text('Continue')),
        ],
      ),
    );
    input.dispose();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _requestReset() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _identifier.text.trim());
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Email or phone number')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Send link')),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    try {
      await widget.api.requestPasswordReset(value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('If the account matches, password reset instructions will be sent.')));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _activate() async {
    final phone = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => _ParentActivationPage(api: widget.api)));
    if (phone != null && mounted) setState(() => _identifier.text = phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolName = _branding?['name']?.toString() ?? '';
    final shortName = _branding?['short_name']?.toString() ?? schoolName;
    final logoUrl = _branding?['logo_url']?.toString() ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundImage: logoUrl.isEmpty ? null : NetworkImage(logoUrl),
                  child: Text(_initials(shortName), style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimaryContainer)),
                ),
                const SizedBox(height: 16),
                Text(schoolName, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('Parent app', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TextField(controller: _identifier, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email or phone number')),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: !_showPassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility))),
                ),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _requestReset, child: const Text('Forgot password?'))),
                if (_error != null) ...[const SizedBox(height: 8), _ErrorPanel(message: errorMessage(_error!))],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy || _loadingBranding || _branding == null ? null : _submit,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
                ),
                TextButton(onPressed: _busy ? null : _activate, child: const Text('I have a parent activation slip')),
                if (_branding == null && !_loadingBranding) TextButton(onPressed: _loadBranding, child: const Text('Retry school connection')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentActivationPage extends StatefulWidget {
  const _ParentActivationPage({required this.api});
  final ApiClient api;
  @override
  State<_ParentActivationPage> createState() => _ParentActivationPageState();
}

class _ParentActivationPageState extends State<_ParentActivationPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _verified = false;
  bool _accepted = false;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() { _phone.dispose(); _code.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _verify() async {
    setState(() { _busy = true; _error = null; });
    try {
      await widget.api.verifyActivation(_phone.text, _code.text);
      if (mounted) setState(() => _verified = true);
    } catch (error) { if (mounted) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _complete() async {
    if (_password.text.length < 10 || _password.text != _confirm.text || !_accepted) {
      setState(() => _error = 'Use at least 10 characters, confirm the password, and accept the school policy.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.api.completeActivation(_password.text, true);
      if (mounted) Navigator.pop(context, _phone.text.trim());
    } catch (error) { if (mounted) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Parent activation')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(_verified ? 'Set your password' : 'Verify activation slip', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (!_verified) ...[
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number on file')),
            const SizedBox(height: 12),
            TextField(controller: _code, decoration: const InputDecoration(labelText: 'Activation code')),
          ] else ...[
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 12),
            TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
            CheckboxListTile(value: _accepted, contentPadding: EdgeInsets.zero, title: const Text('I accept the school policy'), onChanged: (value) => setState(() => _accepted = value == true)),
          ],
          if (_error != null) _ErrorPanel(message: errorMessage(_error!)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _verified ? _complete : _verify, child: Text(_busy ? 'Please wait…' : _verified ? 'Complete activation' : 'Verify code')),
        ]),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(padding: const EdgeInsets.all(14), child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
      );
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String errorMessage(Object error) => error.toString();

