import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_loading_skeleton.dart';

class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key, required this.me, required this.studentId});
  final Map<String, dynamic> me;
  final String studentId;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late Future<dynamic> _profile;
  bool _submitting = false;
  bool _showPassword = false;

  Map<String, dynamic> get _user => widget.me['user'] is Map
      ? Map<String, dynamic>.from(widget.me['user'] as Map)
      : <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _profile = ApiClient.instance.getChildProfile(widget.studentId);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || !_email.text.trim().contains('@') || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email and your current password.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.requestEmailChange(_email.text.trim(), _password.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation link sent. Your email changes after you open it.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact details')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Email', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          const Text('Current email'),
          const SizedBox(height: 6),
          TextFormField(initialValue: user['email']?.toString() ?? '', readOnly: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 14),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email', prefixIcon: Icon(Icons.alternate_email))),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'Your password', suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
          const SizedBox(height: 6),
          Text('We ask for it to confirm it’s you.', style: TextStyle(color: muted, fontSize: 12)),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Phone', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Phone number'),
          const SizedBox(height: 6),
          TextFormField(initialValue: user['phone']?.toString() ?? 'Not provided', readOnly: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), suffixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 12),
          _schoolContactCard(_profile, muted),
        ]))),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 9, 18, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send confirmation link'))),
        const SizedBox(height: 8),
        Text('We’ll send a link to the new address. Your email changes when you open it.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      ]))),
    );
  }

  Widget _schoolContactCard(Future<dynamic> profile, Color muted) => FutureBuilder<dynamic>(
        future: profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'inline');
          if (snapshot.hasError || snapshot.data is! Map) return Text('Phone changes are managed by your school office. School contact details are unavailable.', style: TextStyle(color: muted));
          final office = (snapshot.data as Map)['office'] is Map ? Map<String, dynamic>.from((snapshot.data as Map)['office'] as Map) : <String, dynamic>{};
          final phone = office['phone']?.toString();
          final email = office['email']?.toString();
          if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) return Text('Phone changes are managed by your school office. Contact details were not provided by the school.', style: TextStyle(color: muted));
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSky : AppColors.sky, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.support_agent_outlined),
              const SizedBox(width: 10),
              Expanded(child: Wrap(children: [
                const Text('To change your phone number, contact the school office. '),
                if (phone != null && phone.isNotEmpty) _contactLink(phone, Uri(scheme: 'tel', path: phone)),
                if (phone != null && phone.isNotEmpty && email != null && email.isNotEmpty) const Text(' · '),
                if (email != null && email.isNotEmpty) _contactLink(email, Uri(scheme: 'mailto', path: email)),
              ])),
            ]),
          );
        },
      );

  Widget _contactLink(String label, Uri uri) => InkWell(onTap: () => launchUrl(uri), child: Text(label, style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w700)));
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _submitting = false;

  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final name = widget.user['full_name']?.toString().toLowerCase() ?? '';
    final email = widget.user['email']?.toString().toLowerCase() ?? '';
    final next = _next.text;
    if (_current.text.isEmpty || next.length < 10 || _confirm.text != next ||
        (name.isNotEmpty && next.toLowerCase().contains(name.split(' ').first)) ||
        (email.isNotEmpty && next.toLowerCase().contains(email.split('@').first))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check the password requirements and try again.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.changePassword(_current.text, next);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.muted;
    final lengthOk = _next.text.length >= 10;
    final name = widget.user['full_name']?.toString().toLowerCase() ?? '';
    final email = widget.user['email']?.toString().toLowerCase() ?? '';
    final similarOk = _next.text.isEmpty || ((!name.isNotEmpty || !_next.text.toLowerCase().contains(name.split(' ').first)) && (!email.isNotEmpty || !_next.text.toLowerCase().contains(email.split('@').first)));
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), children: [
        _passwordField('Current password', _current, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
        const SizedBox(height: 18),
        _passwordField('New password', _next, _showNext, () => setState(() => _showNext = !_showNext), onChanged: (_) => setState(() {})),
        const SizedBox(height: 18),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _next.text.isEmpty ? 0 : (lengthOk ? 1 : _next.text.length / 10), minHeight: 6)),
        const SizedBox(height: 8),
        _requirement('At least 10 characters', lengthOk, muted),
        _requirement('Not a commonly used or leaked password', false, muted),
        _requirement('Not too similar to your name or email', similarOk && _next.text.isNotEmpty, muted),
        _requirement('Not used in your last 5 passwords', false, muted),
        const SizedBox(height: 14),
        _passwordField('Confirm new password', _confirm, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update password'))),
        const SizedBox(height: 10),
        Text('You stay signed in on this device. Other devices are signed out.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      ]))),
    );
  }

  Widget _passwordField(String label, TextEditingController controller, bool shown, VoidCallback toggle, {ValueChanged<String>? onChanged}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextField(controller: controller, obscureText: !shown, onChanged: onChanged, decoration: InputDecoration(labelText: label, suffixIcon: IconButton(onPressed: toggle, icon: Icon(shown ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
      );

  Widget _requirement(String text, bool satisfied, Color muted) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(satisfied ? Icons.check_circle_outline : Icons.circle_outlined, size: 21, color: satisfied ? AppColors.successInk : muted), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: muted)))]));
}

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key, required this.children, required this.selectedChildId});
  final List<Map<String, dynamic>> children;
  final String selectedChildId;

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  late String _studentId;
  late DateTime _start;
  late DateTime _end;
  late DateTime _earliest;
  late DateTime _lastDate;
  late Future<dynamic> _availability;
  late Future<dynamic> _rangeCount;
  final _reason = TextEditingController();
  File? _document;
  String? _fileName;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.selectedChildId;
    final now = DateTime.now();
    _earliest = DateTime(now.year, now.month, now.day);
    _lastDate = DateTime(now.year + 1, now.month, now.day);
    _start = _earliest;
    _end = _start;
    _availability = _loadAvailability();
    _rangeCount = _loadCount();
  }

  @override
  void dispose() { _reason.dispose(); super.dispose(); }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _pretty(DateTime value) => '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';
  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
  Map<String, dynamic> get _child => widget.children.firstWhere((item) => item['id'].toString() == _studentId, orElse: () => widget.children.first);

  Future<dynamic> _loadAvailability() => ApiClient.instance.getWorkingDays(_studentId, _date(_earliest), _date(_lastDate));
  Future<dynamic> _loadCount() => ApiClient.instance.getWorkingDays(_studentId, _date(_start), _date(_end));

  Future<void> _selectChild(String? id) async {
    if (id == null || id == _studentId) return;
    final now = DateTime.now();
    setState(() {
      _studentId = id;
      _earliest = DateTime(now.year, now.month, now.day);
      _lastDate = DateTime(now.year + 1, now.month, now.day);
      _start = _earliest;
      _end = _start;
      _availability = _loadAvailability();
      _rangeCount = _loadCount();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    dynamic availability;
    try {
      availability = await _availability;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave availability is unavailable. Please retry.')));
      return;
    }
    if (!mounted) return;
    if (availability is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave availability is unavailable. Please retry.')));
      return;
    }
    final earliestValue = availability['earliest_start']?.toString();
    final earliest = earliestValue == null ? _earliest : DateTime.tryParse(earliestValue) ?? _earliest;
    if (earliest.isAfter(_lastDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The school has not provided an available leave date.')));
      return;
    }
    final firstDate = isStart ? earliest : _start;
    final initialDate = isStart ? (_start.isBefore(earliest) ? earliest : _start) : (_end.isBefore(_start) ? _start : _end);
    final date = await showDatePicker(context: context, firstDate: firstDate, lastDate: _lastDate, initialDate: initialDate);
    if (date != null) setState(() {
      if (isStart) {
        _start = date;
        if (_end.isBefore(date)) _end = date;
      } else {
        _end = date;
      }
      _rangeCount = _loadCount();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
      if (result == null || result.files.isEmpty || result.files.single.path == null) return;
      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a PDF, JPG, or PNG up to 5 MB.')));
        return;
      }
      setState(() { _document = File(file.path!); _fileName = file.name; });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the file picker: $error')));
    }
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a reason for the leave request.')));
      return;
    }
    try {
      final availability = await ApiClient.instance.getWorkingDays(_studentId, _date(_start), _date(_end));
      if (availability is! Map || (availability['working_days'] as num?) == null) {
        throw const FormatException('The school did not return leave availability for these dates.');
      }
      if ((availability['working_days'] as num).toInt() == 0) {
        throw const FormatException('Choose at least one school working day.');
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.createLeaveRequest(_studentId, startsOn: _date(_start), endsOn: _date(_end), reason: _reason.text.trim(), document: _document);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request sent to the class teacher.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Request leave'), Text('${_child['full_name'] ?? ''} · ${_child['class_name'] ?? ''} ${_child['section_name'] ?? ''}', style: TextStyle(fontSize: 12, color: muted))])),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), children: [
        const Text('Child'),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(value: _studentId, items: [for (final child in widget.children) DropdownMenuItem(value: child['id'].toString(), child: Text('${child['full_name']} · ${child['class_name'] ?? ''} ${child['section_name'] ?? ''}'))], onChanged: widget.children.length > 1 ? _selectChild : null),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _dateButton('From', _start, () => _pickDate(isStart: true))),
          const SizedBox(width: 12),
          Expanded(child: _dateButton('To', _end, () => _pickDate(isStart: false))),
        ]),
        const SizedBox(height: 12),
        FutureBuilder<dynamic>(future: _availability, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'inline');
          if (snapshot.hasError || snapshot.data is! Map) return TextButton.icon(onPressed: () => setState(() { _availability = _loadAvailability(); }), icon: const Icon(Icons.refresh), label: const Text('Retry leave availability'));
          return FutureBuilder<dynamic>(future: _rangeCount, builder: (context, countSnapshot) {
            if (countSnapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'inline');
            if (countSnapshot.hasError || countSnapshot.data is! Map) return TextButton.icon(onPressed: () => setState(() { _rangeCount = _loadCount(); }), icon: const Icon(Icons.refresh), label: const Text('Retry working day count'));
            return Align(alignment: Alignment.centerLeft, child: Chip(label: Text('${countSnapshot.data['working_days'] ?? 0} working days'), backgroundColor: dark ? AppColors.darkSky : AppColors.sky));
          });
        }),
        const SizedBox(height: 8),
        const Text('Reason *'),
        const SizedBox(height: 7),
        TextField(controller: _reason, minLines: 4, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height: 20),
        Row(children: [const Text('Document'), const SizedBox(width: 5), Text('optional', style: TextStyle(fontSize: 12))]),
        const SizedBox(height: 7),
        OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file), label: Text(_fileName ?? 'Attach a note or certificate', overflow: TextOverflow.ellipsis)),
        if (_fileName != null) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() { _document = null; _fileName = null; }), icon: const Icon(Icons.close), label: const Text('Remove'))),
        const SizedBox(height: 4),
        Text('PDF, JPG, or PNG up to 5 MB', style: TextStyle(color: muted, fontSize: 12)),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 14), child: SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: _submitting ? null : _submit, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined), label: const Text('Send to class teacher'))))),
    );
  }

  Widget _dateButton(String label, DateTime value, VoidCallback onTap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 7),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_month_outlined, size: 18), label: Text(_pretty(value), maxLines: 1, overflow: TextOverflow.ellipsis))),
      ]);
}
