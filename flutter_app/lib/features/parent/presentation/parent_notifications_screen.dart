import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_loading_skeleton.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key, this.onUnreadCountChanged});
  final VoidCallback? onUnreadCountChanged;

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  bool _unreadOnly = false;
  late Future<dynamic> _notifications;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _notifications = ApiClient.instance.getNotifications(unread: _unreadOnly);
  void _reload() => setState(_load);

  Future<void> _markRead(String id) async {
    try {
      await ApiClient.instance.markNotificationRead(id);
      _reload();
      widget.onUnreadCountChanged?.call();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.markAllNotificationsRead();
      _reload();
      widget.onUnreadCountChanged?.call();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? AppColors.darkInk : AppColors.ink;
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    return RefreshIndicator(onRefresh: () async => _reload(), child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
      Row(children: [
        Expanded(child: Text('Notices', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: text, letterSpacing: -0.4))),
        TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
      ]),
      const SizedBox(height: 8),
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('All')), ButtonSegment(value: true, label: Text('Unread'))],
        selected: {_unreadOnly},
        onSelectionChanged: (values) => setState(() { _unreadOnly = values.first; _load(); }),
      ),
      const SizedBox(height: 12),
      FutureBuilder<dynamic>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const ApiLoadingSkeleton(variant: 'list');
          if (snapshot.hasError) return _error(snapshot.error.toString());
          if (snapshot.data is! Map || (snapshot.data as Map)['items'] is! List) return _error('The server returned invalid notification data.');
          final items = (snapshot.data as Map)['items'] as List;
          if (items.isEmpty) return Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('No notices were returned.', style: TextStyle(color: muted))));
          return Column(children: [
            for (final item in items.whereType<Map>()) _notificationCard(item, text, muted, dark),
            const SizedBox(height: 20),
            Text('www.taarro.com', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.1)),
          ]);
        },
      ),
    ]));
  }

  Widget _notificationCard(Map item, Color text, Color muted, bool dark) {
    final read = item['read'] == true;
    final id = item['id']?.toString();
    return Card(
      color: dark ? AppColors.darkSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: !read && id != null ? () => _markRead(id) : null,
        child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(_icon(item['kind']?.toString() ?? ''), color: read ? muted : (dark ? AppColors.darkPrimary : AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title']?.toString() ?? 'Notice', style: TextStyle(color: text, fontWeight: read ? FontWeight.w600 : FontWeight.w800)),
            if (item['body'] != null) ...[const SizedBox(height: 4), Text(item['body'].toString(), style: TextStyle(color: muted, height: 1.35))],
            if (item['created_at'] != null) ...[const SizedBox(height: 6), Text(item['created_at'].toString(), style: TextStyle(color: muted, fontSize: 11))],
          ])),
          if (!read) const Padding(padding: EdgeInsets.only(left: 8, top: 6), child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary)),
        ])),
      ),
    );
  }

  Widget _error(String message) => Card(color: AppColors.dangerBg, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(message, style: const TextStyle(color: AppColors.dangerInk)), TextButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
}

IconData _icon(String kind) => switch (kind.toLowerCase()) {
      'assignment' => Icons.menu_book_outlined,
      'attendance' => Icons.event_available_outlined,
      'fee' => Icons.account_balance_wallet_outlined,
      'marks' => Icons.grade_outlined,
      _ => Icons.notifications_none_rounded,
    };
