import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../parent/presentation/parent_widgets.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key, required this.api, required this.child});
  final ApiClient api;
  final JsonMap child;
  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  JsonMap? _profile;
  Object? _error;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final result = await widget.api.getChildProfile(widget.child['id'].toString());
      if (result is! Map) throw const FormatException('The school server returned invalid child profile data.');
      _maps((result as Map)['guardians']);
      if (mounted) setState(() { _profile = Map<String, dynamic>.from(result); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _profile = null; _error = error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name']?.toString() ?? widget.child['full_name']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Child profile')),
      body: _error != null
          ? ListView(padding: const EdgeInsets.all(16), children: [ApiErrorPanel(message: readableError(_error!), onRetry: _load)])
          : _profile == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Center(child: Column(children: [
                    ParentAvatar(name: name, photoUrl: _profile!['photo_url']?.toString(), radius: 48),
                    const SizedBox(height: 12),
                    Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${_profile!['class_name'] ?? ''} ${_profile!['section_name'] ?? ''} · Roll ${_profile!['roll_no'] ?? '—'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                  const SizedBox(height: 18),
                  Card(child: Column(children: [
                    ParentInfoRow(label: 'Admission no.', value: _profile!['admission_no']?.toString() ?? '—'),
                    ParentInfoRow(label: 'Date of birth', value: apiDate(_profile!['date_of_birth'])),
                    if (_profile!['house'] is Map) ParentInfoRow(label: 'House', value: (_profile!['house'] as Map)['name']?.toString() ?? ''),
                  ])),
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Guardians', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ..._maps(_profile!['guardians']).map((guardian) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(initials(guardian['full_name']?.toString() ?? ''))),
                      title: Text(guardian['full_name']?.toString() ?? ''),
                      subtitle: Text([
                        guardian['relationship']?.toString() ?? '',
                        if (guardian['is_you'] == true) 'You',
                        guardian['phone']?.toString() ?? '',
                      ].where((value) => value.isNotEmpty).join(' · ')),
                    )),
                    if (_profile!['address'] is Map) ...[
                      const Divider(),
                      ParentInfoRow(label: 'Address', value: _address(_profile!['address'] as Map)),
                    ],
                  ]))),
                  if (_profile!['office'] is Map) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text([
                    'School office',
                    (_profile!['office'] as Map)['phone']?.toString() ?? '',
                    (_profile!['office'] as Map)['email']?.toString() ?? '',
                  ].where((value) => value.isNotEmpty).join('\n')))),
                  Card(child: Column(children: [
                    ListTile(leading: const Icon(Icons.calendar_month_outlined), title: const Text('Class calendar'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildCalendarScreen(api: widget.api, child: widget.child)))),
                    ListTile(leading: const Icon(Icons.event_note_outlined), title: const Text('Leave requests'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveRequestsScreen(api: widget.api, child: widget.child)))),
                  ])),
                  const SizedBox(height: 8),
                ]),
    );
  }
}

class ChildCalendarScreen extends StatefulWidget {
  const ChildCalendarScreen({super.key, required this.api, required this.child});
  final ApiClient api;
  final JsonMap child;
  @override
  State<ChildCalendarScreen> createState() => _ChildCalendarScreenState();
}

class _ChildCalendarScreenState extends State<ChildCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<JsonMap>? _events;
  Object? _error;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final from = DateTime(_month.year, _month.month, 1);
    final to = DateTime(_month.year, _month.month + 1, 0);
    try {
      final result = await widget.api.getCalendar(widget.child['id'].toString(), DateFormat('yyyy-MM-dd').format(from), DateFormat('yyyy-MM-dd').format(to));
      if (result is! List || result.any((item) => item is! Map)) throw const FormatException('The school server returned invalid calendar data.');
      if (mounted) setState(() { _events = result.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _events = null; _error = error; });
    }
  }

  void _changeMonth(int amount) { setState(() { _month = DateTime(_month.year, _month.month + amount); _events = null; }); _load(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Class calendar')),
        body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text(DateFormat('MMMM yyyy').format(_month), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
            IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
          ]),
          if (_error != null)
            ApiErrorPanel(message: readableError(_error!), onRetry: _load)
          else if (_events == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_events!.isEmpty)
            const ParentEmptyCard(message: 'No calendar events for this month.')
          else
            ..._events!.map((event) => Card(child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(event['name']?.toString() ?? ''),
              subtitle: Text([
                '${apiDate(event['starts_on'])}${event['ends_on'] != event['starts_on'] ? ' – ${apiDate(event['ends_on'])}' : ''}',
                event['description']?.toString() ?? '',
                if (event['reopens_on'] != null) 'School reopens ${apiDate(event['reopens_on'])}',
              ].where((value) => value.isNotEmpty).join('\n')),
              trailing: event['kind'] == null ? null : Text(event['kind'].toString()),
            ))),
        ])),
      );
}

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key, required this.api, required this.child});
  final ApiClient api;
  final JsonMap child;
  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  List<JsonMap>? _requests;
  Object? _error;
  bool _busy = false;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final result = await widget.api.getLeaveRequests(widget.child['id'].toString());
      if (result is! List || result.any((item) => item is! Map)) throw const FormatException('The school server returned invalid leave request data.');
      if (mounted) setState(() { _requests = result.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false); _error = null; });
    } catch (error) {
      if (mounted) setState(() { _requests = null; _error = error; });
    }
  }

  Future<void> _newRequest() async {
    final draft = await showDialog<_LeaveDraft>(context: context, builder: (_) => _LeaveRequestDialog(api: widget.api, studentId: widget.child['id'].toString()));
    if (draft == null) return;
    if (draft.file != null && draft.file!.path == null) {
      showParentMessage(context, 'The selected file is not available to upload from this device.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.createLeaveRequest(
        widget.child['id'].toString(),
        startsOn: DateFormat('yyyy-MM-dd').format(draft.start),
        endsOn: DateFormat('yyyy-MM-dd').format(draft.end),
        reason: draft.reason,
        filePath: draft.file?.path,
        fileName: draft.file?.name,
        idempotencyKey: 'leave-${DateTime.now().microsecondsSinceEpoch}',
      );
      await _load();
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(JsonMap request) async {
    final id = request['id']?.toString() ?? '';
    final version = request['version'];
    if (id.isEmpty || version is! num) {
      showParentMessage(context, 'The school server returned incomplete leave request data.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.withdrawLeaveRequest(widget.child['id'].toString(), id, version.toInt());
      await _load();
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(JsonMap request) async {
    final id = request['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final result = await widget.api.getLeaveDocument(widget.child['id'].toString(), id);
      if (result is! Map || result['url'] is! String) throw const FormatException('The school server returned an invalid document link.');
      final uri = Uri.parse(result['url'].toString());
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw const FormatException('The document link could not be opened on this device.');
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Leave requests')),
        floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _newRequest, icon: const Icon(Icons.add), label: const Text('Request leave')),
        body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_error != null)
            ApiErrorPanel(message: readableError(_error!), onRetry: _load)
          else if (_requests == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_requests!.isEmpty)
            const ParentEmptyCard(message: 'No leave requests yet.')
          else
            ..._requests!.map((request) {
              final canWithdraw = ['pending', 'requested'].contains(request['status']?.toString());
              final document = request['document'] is Map ? Map<String, dynamic>.from(request['document'] as Map) : null;
              return Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                ListTile(
                  title: Text(request['reason']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${apiDate(request['starts_on'])} – ${apiDate(request['ends_on'])}\n${_title(request['status']?.toString() ?? '')} · ${apiTimestamp(request['requested_at'])}'),
                  isThreeLine: true,
                  trailing: canWithdraw ? IconButton(tooltip: 'Withdraw request', onPressed: _busy ? null : () => _withdraw(request), icon: const Icon(Icons.close)) : null,
                ),
                if (document != null && document['name'] != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _openDocument(request), icon: const Icon(Icons.attach_file), label: Text(document['name'].toString()))),
                if (request['decision_note']?.toString().isNotEmpty == true) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Align(alignment: Alignment.centerLeft, child: Text(request['decision_note'].toString()))),
              ])));
            }),
          if (_busy) const LinearProgressIndicator(),
        ])),
      );
}

class _LeaveDraft {
  const _LeaveDraft({required this.start, required this.end, required this.reason, this.file});
  final DateTime start;
  final DateTime end;
  final String reason;
  final PlatformFile? file;
}

class _LeaveRequestDialog extends StatefulWidget {
  const _LeaveRequestDialog({required this.api, required this.studentId});
  final ApiClient api;
  final String studentId;
  @override
  State<_LeaveRequestDialog> createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends State<_LeaveRequestDialog> {
  final _reason = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  PlatformFile? _file;
  int? _workingDays;
  DateTime? _earliestStart;
  Object? _dateError;
  bool _checkingDates = false;

  @override
  void dispose() { _reason.dispose(); super.dispose(); }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (value == null) return;
    setState(() {
      if (start) _start = value; else _end = value;
      _workingDays = null;
      _dateError = null;
    });
    await _checkDates();
  }

  Future<void> _checkDates() async {
    if (_start == null || _end == null || _end!.isBefore(_start!)) return;
    setState(() { _checkingDates = true; _dateError = null; });
    try {
      final result = await widget.api.getWorkingDays(
        widget.studentId,
        DateFormat('yyyy-MM-dd').format(_start!),
        DateFormat('yyyy-MM-dd').format(_end!),
      );
      if (result is! Map || result['working_days'] is! num || result['earliest_start'] == null) {
        throw const FormatException('The school server returned invalid working day data.');
      }
      final earliest = DateTime.tryParse(result['earliest_start'].toString());
      if (earliest == null) throw const FormatException('The school server returned an invalid earliest leave date.');
      if (mounted) setState(() {
        _workingDays = (result['working_days'] as num).toInt();
        _earliestStart = earliest;
        if (_start!.isBefore(earliest)) _dateError = FormatException('Leave can first be requested from ${apiDate(earliest)}.');
        if (_workingDays == 0) _dateError = const FormatException('There are no school working days in this date range.');
      });
    } catch (error) {
      if (mounted) setState(() => _dateError = error);
    } finally {
      if (mounted) setState(() => _checkingDates = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
    if (result != null && result.files.isNotEmpty) setState(() => _file = result.files.first);
  }

  @override
  Widget build(BuildContext context) {
    final invalidRange = _start == null || _end == null || _end!.isBefore(_start!);
    final invalidEarliest = _earliestStart != null && _start != null && _start!.isBefore(_earliestStart!);
    final canSubmit = !invalidRange && !invalidEarliest && !_checkingDates && _dateError == null && _workingDays != null && _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Request leave'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(contentPadding: EdgeInsets.zero, title: Text(_start == null ? 'Start date' : apiDate(_start)), trailing: const Icon(Icons.calendar_today), onTap: () => _pickDate(true)),
        ListTile(contentPadding: EdgeInsets.zero, title: Text(_end == null ? 'End date' : apiDate(_end)), trailing: const Icon(Icons.calendar_today), onTap: () => _pickDate(false)),
        if (_checkingDates) const LinearProgressIndicator(),
        if (_workingDays != null) Align(alignment: Alignment.centerLeft, child: Text('$_workingDays working day(s) in this range')),
        if (_dateError != null) Align(alignment: Alignment.centerLeft, child: Text(readableError(_dateError!), style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 8),
        TextField(controller: _reason, onChanged: (_) => setState(() {}), maxLines: 3, decoration: const InputDecoration(labelText: 'Reason')),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file), label: Text(_file?.name ?? 'Attach document (optional)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: canSubmit ? () => Navigator.pop(context, _LeaveDraft(start: _start!, end: _end!, reason: _reason.text.trim(), file: _file)) : null, child: const Text('Send request')),
      ],
    );
  }
}

List<JsonMap> _maps(dynamic value) {
  if (value is! List || value.any((item) => item is! Map)) throw const FormatException('The school server returned invalid list data.');
  return value.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false);
}

String _address(Map address) => [address['line'], address['city'], address['state'], address['pin_code']].where((value) => value != null && value.toString().isNotEmpty).join(', ');
String _title(String value) => value.split(RegExp(r'[_ -]+')).where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
