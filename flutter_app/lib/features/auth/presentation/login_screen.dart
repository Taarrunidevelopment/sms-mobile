import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../parent/presentation/parent_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String _schoolName = 'Parent Portal';

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
    try {
      final data = await ApiClient.instance.fetchBranding();
      if (data is Map && mounted) {
        final name = (data['name'] ?? data['short_name'])?.toString().trim();
        if (name != null && name.isNotEmpty) setState(() => _schoolName = name);
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    }
  }

  Future<String?> _askCode({required String title, required String message}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          const SizedBox(height: 12),
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Verification code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _requestPasswordReset() async {
    final identifier = TextEditingController(text: _identifier.text.trim());
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Reset password'),
      content: TextField(controller: identifier, autofocus: true, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email or phone')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, identifier.text.trim()), child: const Text('Send link'))],
    ));
    identifier.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await ApiClient.instance.requestPasswordReset(value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('If the account matches, password reset instructions will be sent.')));
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    }
  }

  Future<void> _activateAccount() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const ParentActivationScreen()));
  }

  Future<void> _signIn() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email or phone number and password.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final api = ApiClient.instance;
      final loginResponse = await api.login(_identifier.text, _password.text, remember: true);
      final status = loginResponse is Map ? loginResponse['status']?.toString() : null;
      if (status == 'two_factor_required') {
        final code = await _askCode(title: 'Two-step verification', message: 'Enter a code from your authenticator app or a recovery code.');
        if (code == null) return;
        final verified = await api.verifyTwoFactor(code);
        if (verified is Map && verified['status']?.toString() != 'signed_in') {
          throw const ApiProblemException(title: 'Two-step verification did not complete.', type: 'two-factor-incomplete', status: 401);
        }
      } else if (status == 'two_factor_setup_required') {
        final setup = await api.setupTwoFactor();
        if (setup is! Map) throw const FormatException('The server returned invalid two-step setup data.');
        final manualKey = setup['manual_key']?.toString() ?? '';
        final code = await _askCode(title: 'Set up two-step verification', message: 'Add this key to your authenticator app, then enter its code.\n\n$manualKey');
        if (code == null) return;
        final confirmed = await api.confirmTwoFactorSetup(code);
        if (confirmed is Map && confirmed['recovery_codes'] is List && mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Save recovery codes'),
              content: SelectableText((confirmed['recovery_codes'] as List).join('\n')),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
            ),
          );
        }
      } else if (status != 'signed_in') {
        throw ApiProblemException(title: 'The server returned an unexpected sign-in status: ${status ?? 'missing'}.', type: 'login-response', status: 502);
      }

      final meResult = await api.getMe();
      if (meResult is! Map) throw const FormatException('The server returned invalid account data.');
      final me = Map<String, dynamic>.from(meResult);
      final areas = me['areas'];
      if (areas is! List || !areas.contains('parent')) {
        throw const ApiProblemException(title: 'This account does not have parent portal access.', type: 'staff-only', status: 403);
      }
      if (me['user'] is! Map || (me['user'] as Map)['full_name']?.toString().trim().isEmpty != false ||
          (me['user'] as Map)['email'] == null || (me['user'] as Map)['phone'] == null ||
          me['school'] is! Map || (me['school'] as Map)['name']?.toString().trim().isEmpty != false ||
          me['preferences'] is! Map) {
        throw const FormatException('The server returned incomplete account or school data.');
      }
      final childrenResult = await api.getChildren();
      if (childrenResult is! List) throw const FormatException('The server returned an invalid child list.');
      final children = childrenResult.map((item) {
        if (item is! Map || item['id'] == null || item['full_name']?.toString().trim().isEmpty != false) {
          throw const FormatException('The server returned an incomplete child record.');
        }
        return Map<String, dynamic>.from(item);
      }).toList(growable: false);
      if (children.isEmpty) {
        throw const ApiProblemException(title: 'No children are linked to this parent account.', type: 'not-a-guardian', status: 403);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ParentHomeScreen(me: me, children: children)));
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.auroraGradient),
        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.school_rounded, size: 52, color: Colors.white),
              const SizedBox(height: 12),
              Text(_schoolName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
              const Text('Parent Portal', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              Card(
                color: dark ? AppColors.darkSurface : Colors.white,
                child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Sign in with your email or phone'),
                  const SizedBox(height: 18),
                  TextField(controller: _identifier, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email or phone', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    onSubmitted: (_) => _busy ? null : _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility)),
                    ),
                  ),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _requestPasswordReset, child: const Text('Forgot password?'))),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: dark ? AppColors.darkRose : AppColors.dangerBg, borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: TextStyle(color: dark ? AppColors.darkRoseInk : AppColors.dangerInk))),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(onPressed: _busy ? null : _signIn, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in')),
                  const SizedBox(height: 4),
                  TextButton(onPressed: _busy ? null : _activateAccount, child: const Text('I have a parent activation code')),
                ])),
              ),
            ]),
          ),
        ))),
      ),
    );
  }
}

class ParentActivationScreen extends StatefulWidget {
  const ParentActivationScreen({super.key});
  @override
  State<ParentActivationScreen> createState() => _ParentActivationScreenState();
}

class _ParentActivationScreenState extends State<ParentActivationScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _verified = false;
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _phone.dispose(); _code.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _verify() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ApiClient.instance.verifyActivation(_phone.text, _code.text);
      if (mounted) setState(() => _verified = true);
    } catch (error) { if (mounted) setState(() => _error = errorMessage(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<String?> _askCode(String title, String message) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: Text(title), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message), const SizedBox(height: 12), TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Verification code'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Continue'))],
    ));
    controller.dispose();
    return code == null || code.isEmpty ? null : code;
  }

  Future<void> _complete() async {
    if (_password.text.length < 10 || _password.text != _confirm.text || !_accepted) {
      setState(() => _error = 'Use at least 10 characters, confirm the password, and accept the school policy.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await ApiClient.instance.completeActivation(_password.text, acceptPolicy: _accepted);
      final status = result is Map ? result['status']?.toString() : null;
      if (status == 'two_factor_required') {
        final code = await _askCode('Two-step verification', 'Enter a code from your authenticator app or a recovery code.');
        if (code == null) return;
        await ApiClient.instance.verifyTwoFactor(code);
      } else if (status == 'two_factor_setup_required') {
        final setup = await ApiClient.instance.setupTwoFactor();
        if (setup is! Map) throw const FormatException('The server returned invalid two-step setup data.');
        final code = await _askCode('Set up two-step verification', 'Add this key to your authenticator app, then enter its code.\n\n${setup['manual_key'] ?? ''}');
        if (code == null) return;
        await ApiClient.instance.confirmTwoFactorSetup(code);
      } else if (status != 'signed_in') {
        throw ApiProblemException(title: 'The server returned an unexpected activation status: ${status ?? 'missing'}.', type: 'activation-response', status: 502);
      }
      final meResult = await ApiClient.instance.getMe();
      final childrenResult = await ApiClient.instance.getChildren();
      if (meResult is! Map || childrenResult is! List || !(meResult['areas'] is List && (meResult['areas'] as List).contains('parent'))) {
        throw const FormatException('The server returned incomplete parent account data.');
      }
      final me = Map<String, dynamic>.from(meResult);
      if (me['user'] is! Map || (me['user'] as Map)['full_name']?.toString().trim().isEmpty != false ||
          me['school'] is! Map || (me['school'] as Map)['name']?.toString().trim().isEmpty != false || me['preferences'] is! Map) {
        throw const FormatException('The server returned incomplete parent account data.');
      }
      final children = childrenResult.map((item) {
        if (item is! Map || item['id'] == null || item['full_name']?.toString().trim().isEmpty != false) {
          throw const FormatException('The server returned an incomplete child record.');
        }
        return Map<String, dynamic>.from(item);
      }).toList(growable: false);
      if (children.isEmpty) throw const ApiProblemException(title: 'No children are linked to this parent account.', type: 'not-a-guardian', status: 403);
      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => ParentHomeScreen(me: me, children: children)), (route) => false);
    } catch (error) { if (mounted) setState(() => _error = errorMessage(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Parent activation')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(_verified ? 'Set your password' : 'Verify activation code', style: Theme.of(context).textTheme.headlineSmall),
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
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: AppColors.danger))],
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _verified ? _complete : _verify, child: _busy ? const CircularProgressIndicator() : Text(_verified ? 'Complete activation' : 'Verify code')),
        ]),
      );
}

String errorMessage(Object error) => error.toString();
