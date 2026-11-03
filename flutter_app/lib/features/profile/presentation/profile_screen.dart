import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.me, required this.child, this.colorIndex = 0});
  final Map<String, dynamic> me;
  final Map<String, dynamic> child;
  final int colorIndex;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<dynamic> _profile;
  @override
  void initState() { super.initState(); _load(); }
  void _load() => _profile = ApiClient.instance.getChildProfile(widget.child['id'].toString());

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grade = getParentColorGrade(widget.colorIndex);
    final school = widget.me['school'] is Map ? Map<String, dynamic>.from(widget.me['school'] as Map) : <String, dynamic>{};
    final fg = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    return Scaffold(
      appBar: AppBar(title: const Text('Child profile')),
      body: FutureBuilder<dynamic>(future: _profile, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _error(snapshot.error.toString());
        if (snapshot.data is! Map) return _error('The server returned invalid profile data.');
        final data = Map<String, dynamic>.from(snapshot.data as Map);
        if (data['full_name'] == null || data['full_name'].toString().trim().isEmpty) return _error('The server returned incomplete child profile data.');
        final guardians = data['guardians'] is List ? data['guardians'] as List : const [];
        final address = data['address'] is Map ? Map<String, dynamic>.from(data['address'] as Map) : <String, dynamic>{};
        final house = data['house'] is Map ? Map<String, dynamic>.from(data['house'] as Map) : <String, dynamic>{};
        final office = data['office'] is Map ? Map<String, dynamic>.from(data['office'] as Map) : <String, dynamic>{};
        final name = data['full_name'].toString();
        final addressText = [address['line'], address['city'], address['state'], address['pin_code']]
            .where((value) => value != null && value.toString().isNotEmpty)
            .join(', ');
        return RefreshIndicator(onRefresh: () async => setState(_load), child: ListView(padding: const EdgeInsets.all(18), children: [
          Card(color: dark ? AppColors.darkSurface : grade.cardBg, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            CircleAvatar(radius: 42, backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(name), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: dark ? AppColors.darkPrimary : grade.accentText))),
            const SizedBox(height: 12),
            Text(name, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: fg)),
            Text([data['class_name'], data['section_name'], if (data['roll_no'] != null) 'Roll ${data['roll_no']}'].where((e) => e != null && e.toString().isNotEmpty).join(' · '), style: TextStyle(color: muted)),
            if (school['short_name'] != null || school['name'] != null) Text((school['short_name'] ?? school['name']).toString(), style: TextStyle(color: muted, fontSize: 12)),
          ]))),
          const SizedBox(height: 12),
          _infoCard('Student details', [
            _row('Admission no.', data['admission_no']),
            _row('Date of birth', data['date_of_birth']),
            _row('House', house['name']),
            _row('House colour', house['colour']),
          ], fg, muted),
          const SizedBox(height: 12),
          _infoCard('Guardians', guardians.map<Widget>((guardian) {
            if (guardian is! Map) return const SizedBox.shrink();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(guardian['full_name']?.toString() ?? ''))),
              title: Text(guardian['full_name']?.toString() ?? 'Guardian', style: TextStyle(color: fg)),
              subtitle: Text([guardian['relationship'], if (guardian['is_you'] == true) 'You', guardian['phone']].where((e) => e != null && e.toString().isNotEmpty).join(' · '), style: TextStyle(color: muted)),
            );
          }).toList(), fg, muted),
          const SizedBox(height: 12),
          _infoCard('Address', [
            Text(addressText.isEmpty ? 'Address not provided by the school.' : addressText, style: TextStyle(color: fg)),
          ], fg, muted),
          const SizedBox(height: 12),
          _infoCard('School contact', [
            _row('Phone', office['phone']),
            _row('Email', office['email']),
          ], fg, muted),
          const SizedBox(height: 20),
          Center(child: Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1))),
        ]));
      }),
    );
  }

  Widget _error(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)), TextButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry'))])));

  Widget _infoCard(String title, List<Widget> children, Color fg, Color muted) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: fg)), const SizedBox(height: 10), if (children.isEmpty) Text('No details were returned.', style: TextStyle(color: muted)) else ...children])));

  Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))), Text(value?.toString() ?? 'Not provided')]));
}

String _initials(String name) => name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
