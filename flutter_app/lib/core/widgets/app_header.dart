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
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? AppColors.darkInk : AppColors.ink;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final firstName = userName.trim().split(RegExp(r'\s+')).first;
    final roleBg = isDark ? AppColors.darkPeach : AppColors.peach;
    final roleText = isDark ? AppColors.darkPeachInk : AppColors.peachInk;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 3, 8, 4),
        child: Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 27,
                child: Row(
                  children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/taarro_logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.school_rounded, size: 23, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text('Taarro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: foreground, letterSpacing: -0.2)),
                  const SizedBox(width: 7),
                  Text('|', style: TextStyle(color: muted.withOpacity(0.55), fontSize: 12)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Making Education Smarter with AI.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                    ),
                  ),
                  ],
                ),
              ),
              Divider(height: 5, thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.border.withOpacity(0.7)),
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.school_rounded, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schoolName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: foreground, letterSpacing: -0.2)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(child: Text('Good morning, $firstName', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: muted))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: isDark ? AppColors.darkPeachInk.withOpacity(0.25) : const Color(0xFFFCD8C9))),
                              child: Text('Parent', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: roleText)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
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
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 19, color: muted),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    tooltip: 'Notifications',
                    onPressed: onOpenNotifications,
                    icon: Badge(isLabelVisible: hasUnreadError || unreadCount > 0, label: Text(hasUnreadError ? '!' : unreadCount > 99 ? '99+' : '$unreadCount'), child: Icon(Icons.notifications_none_rounded, size: 20, color: muted)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    tooltip: 'Account',
                    onPressed: onOpenProfile,
                    icon: Icon(Icons.account_circle_rounded, size: 22, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
