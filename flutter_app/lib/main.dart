import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/parent/presentation/parent_home_screen.dart';
import 'features/parent/presentation/parent_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(const NorthfieldParentApp());
}

class NorthfieldParentApp extends StatefulWidget {
  const NorthfieldParentApp({super.key});

  @override
  State<NorthfieldParentApp> createState() => _NorthfieldParentAppState();
}

class _NorthfieldParentAppState extends State<NorthfieldParentApp> {
  final api = ApiClient.instance;
  JsonMap? me;
  List<JsonMap> children = [];
  ThemeMode themeMode = ThemeMode.system;
  Object? startupError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() { loading = true; startupError = null; });
    try {
      await api.initialize();
      await api.fetchCsrf();
      try {
        final profile = _asMap(await api.getMe());
        if (!(profile['areas'] is List && (profile['areas'] as List).contains('parent'))) {
          throw const ApiProblemException(title: 'This account does not have parent portal access.', type: 'staff-only', status: 403);
        }
        _asMap(profile['school']);
        _asMap(profile['user']);
        _asMap(profile['preferences']);
        final linkedChildren = _asList(await api.getChildren());
        me = profile;
        schoolTimeZone = _asMap(profile['school'])['timezone']?.toString() ?? 'UTC';
        children = linkedChildren;
        final preference = _asMap(profile['preferences']);
        themeMode = switch (preference['theme']) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        };
      } on ApiProblemException catch (error) {
        if (error.status == 401) {
          me = null;
          children = [];
        } else {
          rethrow;
        }
      }
    } catch (error) {
      startupError = error;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signedIn(JsonMap profile, List<JsonMap> linkedChildren) async {
    final preference = _asMap(profile['preferences']);
    setState(() {
      me = profile;
      schoolTimeZone = _asMap(profile['school'])['timezone']?.toString() ?? 'UTC';
      children = linkedChildren;
      themeMode = switch (preference['theme']) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
    });
  }

  Future<void> _changeTheme(String theme) async {
    final preferences = _asMap(me?['preferences']);
    await api.savePreferences(
      theme,
      density: preferences['density']?.toString() ?? 'comfortable',
      lastArea: preferences['last_area']?.toString() ?? 'parent',
    );
    if (!mounted) return;
    setState(() => themeMode = switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    });
  }

  Future<void> _signOut() async {
    await api.logout();
    if (mounted) setState(() { me = null; children = []; });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Northfield Parent App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : startupError != null
                ? _StartupError(error: startupError!, onRetry: _bootstrap)
                : me == null
                    ? LoginScreen(api: api, onSignedIn: _signedIn)
                    : ParentHomeScreen(
                        api: api,
                        me: me!,
                        children: children,
                        themeMode: themeMode,
                        onThemeChanged: _changeTheme,
                        onSignOut: _signOut,
                      ),
      );
}

JsonMap _asMap(dynamic value) {
  if (value is! Map) throw const FormatException('The school server returned an invalid response.');
  return Map<String, dynamic>.from(value);
}

List<JsonMap> _asList(dynamic value) {
  if (value is! List) throw const FormatException('The school server returned an invalid child list.');
  final children = value.map((item) => _asMap(item)).toList(growable: false);
  if (children.any((child) => child['id'] == null || child['full_name'] == null)) {
    throw const FormatException('The school server returned an incomplete child record.');
  }
  return children;
}

String errorMessage(Object error) => error.toString();

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text(errorMessage(error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
}
