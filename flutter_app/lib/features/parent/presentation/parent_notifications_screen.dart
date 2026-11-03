import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';
import '../../../core/utils/parent_theme.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key, this.session, this.selectedChildId = 1});
  final Session? session;
  final int selectedChildId;

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  final List<Map<String, dynamic>> _children = [
    {'id': 1, 'name': 'Aarav Kumar'},
    {'id': 2, 'name': 'Diya Kumar'},
  ];

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.menu_book_rounded;
      case 'attendance':
        return Icons.calendar_today_rounded;
      case 'fee':
        return Icons.account_balance_wallet_rounded;
      case 'marks':
        return Icons.military_tech_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getNotificationIconColor(String type, bool isDark) {
    if (isDark) return Colors.white;
    switch (type) {
      case 'assignment':
        return const Color(0xFF9333EA);
      case 'attendance':
        return const Color(0xFF059669);
      case 'fee':
        return const Color(0xFFD97706);
      case 'marks':
        return const Color(0xFFE11D48);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = <AppNotification>[]; // Placeholder for backend data integration
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedChild = _children.firstWhere(
      (c) => c['id'] == widget.selectedChildId,
      orElse: () => _children.first,
    );
    final childIndex = _children.indexOf(selectedChild);
    final safeIndex = childIndex >= 0 ? childIndex : 0;
    final grade = getParentColorGrade(safeIndex);

    final bg = isDark ? AppColors.darkBg : grade.screenBg;
    final surface = isDark ? AppColors.darkSurface : grade.cardBg;
    final textColor = isDark ? AppColors.darkText : grade.textMain;
    final mutedColor = isDark ? AppColors.darkMuted : grade.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : grade.cardBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Notifications & Alerts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : grade.textMain,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : grade.cardBg,
        foregroundColor: isDark ? Colors.white : grade.textMain,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
                'No notifications right now',
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == list.length) {
                  return const TaarroFooter();
                }
                final item = list[idx];
                final isUnread = item.readAt == null;
                final cardBgColor = isUnread
                    ? (isDark ? const Color(0xFF262445) : grade.subtleBg)
                    : surface;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      item.readAt = DateTime.now();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSunken : grade.innerCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Icon(
                              _getNotificationIcon(item.type),
                              color: _getNotificationIconColor(item.type, isDark),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: grade.accentBg,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
