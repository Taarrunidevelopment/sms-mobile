import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/api_loading_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.me, required this.child, this.colorIndex = 0, this.embedded = false, this.onBack});
  final Map<String, dynamic> me;
  final Map<String, dynamic> child;
  final int colorIndex;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<dynamic> _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _profile = ApiClient.instance.getChildProfile(widget.child['id'].toString());

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<dynamic>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SingleChildScrollView(padding: EdgeInsets.all(18), child: ApiLoadingSkeleton(variant: 'profile'));
        }
        if (snapshot.hasError) return _error(snapshot.error.toString());
        if (snapshot.data is! Map) return _error('The server returned invalid profile data.');
        final data = Map<String, dynamic>.from(snapshot.data as Map);
        if (data['full_name'] == null || data['full_name'].toString().trim().isEmpty) return _error('The server returned incomplete child profile data.');
        return _profileContent(data);
      },
    );

    if (!widget.embedded) {
      return Scaffold(appBar: AppBar(title: const Text('Child profile')), body: content);
    }
    return Column(children: [
      if (widget.onBack != null)
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), label: const Text('More'))),
      Expanded(child: content),
    ]);
  }

  Widget _profileContent(Map<String, dynamic> data) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grade = getParentColorGrade(widget.colorIndex);
    final school = widget.me['school'] is Map ? Map<String, dynamic>.from(widget.me['school'] as Map) : <String, dynamic>{};
    final guardians = data['guardians'] is List ? (data['guardians'] as List).whereType<Map>().toList() : <Map>[];
    final address = data['address'] is Map ? Map<String, dynamic>.from(data['address'] as Map) : <String, dynamic>{};
    final house = data['house'] is Map ? Map<String, dynamic>.from(data['house'] as Map) : <String, dynamic>{};
    final office = data['office'] is Map ? Map<String, dynamic>.from(data['office'] as Map) : <String, dynamic>{};
    final fg = dark ? AppColors.darkInk : grade.textMain;
    final muted = dark ? AppColors.darkMuted : grade.textMuted;
    final name = data['full_name'].toString();
    final addressText = [address['line'], address['city'], address['state'], address['pin_code']]
        .where((value) => value != null && value.toString().isNotEmpty)
        .join(', ');

    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
        Card(color: dark ? AppColors.darkSurface : grade.screenBg, child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 18), child: Column(children: [
          CircleAvatar(radius: 43, backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(name), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: dark ? AppColors.darkPrimary : grade.accentText))),
          const SizedBox(height: 12),
          Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 3),
          Text([data['class_name'], data['section_name'], if (data['roll_no'] != null) 'Roll ${data['roll_no']}'].where((value) => value != null && value.toString().isNotEmpty).join(' · '), style: TextStyle(color: muted, fontSize: 14)),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _detailRow('Admission no.', data['admission_no'], fg, muted),
          _detailRow('Date of birth', _formatDate(data['date_of_birth']), fg, muted),
          _detailRow('House', house['name'], fg, muted, suffix: house['colour']),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Guardians', style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 8),
          if (guardians.isEmpty) Text('No guardian details were returned.', style: TextStyle(color: muted))
          else for (final guardian in guardians) _guardianTile(guardian, fg, muted, grade, dark),
          const Divider(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Address', style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(width: 14),
            Expanded(child: Text(addressText.isEmpty ? 'Address not provided by the school.' : addressText, textAlign: TextAlign.end, style: TextStyle(color: fg, height: 1.35))),
          ]),
        ]))),
        const SizedBox(height: 12),
        Card(color: dark ? AppColors.darkPrimarySoft : AppColors.primarySoft, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.support_agent_rounded, color: dark ? AppColors.darkPrimary : AppColors.primary), const SizedBox(width: 9), Expanded(child: Text('Something wrong? Contact the school office', style: TextStyle(color: fg, fontWeight: FontWeight.w700)))]),
          if (office['phone'] != null && office['phone'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _contactRow(Icons.phone_outlined, office['phone'].toString(), Uri(scheme: 'tel', path: office['phone'].toString()), fg),
          ],
          if (office['email'] != null && office['email'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            _contactRow(Icons.email_outlined, office['email'].toString(), Uri(scheme: 'mailto', path: office['email'].toString()), fg),
          ],
          if ((office['phone'] == null || office['phone'].toString().trim().isEmpty) && (office['email'] == null || office['email'].toString().trim().isEmpty))
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('School contact details were not provided.', style: TextStyle(color: muted))),
        ]))),
        if (school['short_name'] != null || school['name'] != null) ...[
          const SizedBox(height: 16),
          Center(child: Text(school['short_name']?.toString().trim().isNotEmpty == true ? school['short_name'].toString() : school['name'].toString(), style: TextStyle(color: muted, fontSize: 11))),
        ],
        const SizedBox(height: 8),
        Center(child: Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1))),
      ]),
    );
  }

  Widget _guardianTile(Map guardian, Color fg, Color muted, ParentColorGrade grade, bool dark) {
    final name = guardian['full_name']?.toString() ?? '';
    final phone = guardian['phone']?.toString();
    final relation = [guardian['relationship'], if (guardian['is_you'] == true) 'You', phone]
        .where((value) => value != null && value.toString().isNotEmpty)
        .join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg, child: Text(_initials(name), style: TextStyle(color: dark ? AppColors.darkPrimary : grade.accentText, fontWeight: FontWeight.w700))),
      title: Text(name, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
      subtitle: Text(relation, style: TextStyle(color: muted)),
      onTap: phone == null || phone.isEmpty ? null : () => _openContact(Uri(scheme: 'tel', path: phone)),
    );
  }

  Widget _detailRow(String label, dynamic value, Color fg, Color muted, {dynamic suffix}) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: muted))),
        if (suffix != null) ...[
          Text(suffix.toString(), style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
        ],
        Text(value?.toString() ?? 'Not provided', textAlign: TextAlign.end, style: TextStyle(color: fg)),
      ]));

  Widget _contactRow(IconData icon, String value, Uri uri, Color fg) => InkWell(
        onTap: () => _openContact(uri),
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: fg, decoration: TextDecoration.underline, fontWeight: FontWeight.w600))),
          Icon(Icons.open_in_new_rounded, size: 14, color: fg),
        ])),
      );

  Future<void> _openContact(Uri uri) async {
    try {
      final opened = await launchUrl(uri);
      if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No app is available to open this contact.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _error(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)), TextButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
}

String _initials(String name) => name.trim().split(RegExp(r'\s+')).where((value) => value.isNotEmpty).take(2).map((value) => value[0].toUpperCase()).join();
String _formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return 'Not provided';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
