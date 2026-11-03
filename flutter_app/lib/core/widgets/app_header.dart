import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.schoolName,
    required this.userName,
    required this.unreadCount,
    this.hasUnreadError = false,
    required this.onOpenNotifications,
    required this.onOpenProfile,
  });

  final String schoolName;
  final String userName;
  final int unreadCount;
  final bool hasUnreadError;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkInk : AppColors.ink;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(_initials(schoolName), style: TextStyle(color: isDark ? AppColors.darkPrimary : AppColors.primary, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(schoolName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11)),
        ])),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onOpenNotifications,
          icon: Badge(isLabelVisible: hasUnreadError || unreadCount > 0, label: Text(hasUnreadError ? '!' : unreadCount > 99 ? '99+' : '$unreadCount'), child: const Icon(Icons.notifications_none_rounded)),
        ),
        IconButton(
          tooltip: 'Account',
          onPressed: onOpenProfile,
          icon: Icon(Icons.account_circle_outlined, color: isDark ? AppColors.darkPrimary : AppColors.primary),
        ),
        IconButton(
          tooltip: isDark ? 'Use light theme' : 'Use dark theme',
          onPressed: () async {
            final next = isDark ? ThemeMode.light : ThemeMode.dark;
            try {
              await ApiClient.instance.savePreferences(next.name);
              ref.read(themeModeProvider.notifier).state = next;
            } catch (error) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
    );
  }
}

String _initials(String value) {
  final words = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (words.isEmpty) return 'S';
  return words.take(2).map((e) => e[0].toUpperCase()).join();
}
