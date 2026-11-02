import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'parent_widgets.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  List<JsonMap>? _items;
  int? _unread;
  Object? _error;
  bool _unreadOnly = false;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _busy = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.api.getNotifications(page: 1, pageSize: 50, unread: _unreadOnly),
        widget.api.getUnreadCount(),
      ]);
      if (results[0] is! Map || results[1] is! Map) throw const FormatException('The school server returned invalid notice data.');
      final page = Map<String, dynamic>.from(results[0] as Map);
      final count = (results[1] as Map)['count'];
      if (count is! num) throw const FormatException('The school server returned an invalid unread notice count.');
      final rawItems = page['items'];
      if (rawItems is! List || rawItems.any((item) => item is! Map)) throw const FormatException('The school server returned an invalid notice list.');
      if (mounted) setState(() {
        _items = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false);
        _unread = count.toInt();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() { _items = null; _unread = null; _error = error; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await widget.api.markNotificationRead(id);
      await _load();
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.api.markAllNotificationsRead();
      await _load();
    } catch (error) {
      if (mounted) showParentMessage(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 28), children: [
          Row(children: [
            Expanded(child: Text('Notices', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            if ((_unread ?? 0) > 0) TextButton(onPressed: _busy ? null : _markAllRead, child: const Text('Mark all read')),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('All'), selected: !_unreadOnly, onSelected: _busy ? null : (_) { setState(() => _unreadOnly = false); _load(); }),
            ChoiceChip(label: Text('Unread · ${_unread ?? '—'}'), selected: _unreadOnly, onSelected: _busy ? null : (_) { setState(() => _unreadOnly = true); _load(); }),
          ]),
          const SizedBox(height: 12),
          if (_error != null)
            ApiErrorPanel(message: readableError(_error!), onRetry: _load)
          else if (_items == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_items!.isEmpty)
            const ParentEmptyCard(message: 'No notices yet.')
          else
            ..._items!.map((item) {
              final read = item['read'] == true;
              final id = item['id']?.toString() ?? '';
              return Card(child: ListTile(
                onTap: read || id.isEmpty ? null : () => _markRead(id),
                leading: Icon(read ? Icons.campaign_outlined : Icons.markunread_outlined),
                title: Text(item['title']?.toString() ?? '', style: TextStyle(fontWeight: read ? FontWeight.w500 : FontWeight.w800)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (item['body']?.toString().isNotEmpty == true) Text(item['body'].toString()),
                  const SizedBox(height: 4),
                  Text(apiTimestamp(item['created_at'])),
                ]),
                isThreeLine: item['body']?.toString().isNotEmpty == true,
              ));
            }),
        ]),
      );
}
