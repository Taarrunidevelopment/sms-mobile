import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({
    super.key,
    required this.session,
    this.isEmbedded = true,
    this.selectedChildId,
    this.onChildSelected,
  });
  final Session session;
  final bool isEmbedded;
  final int? selectedChildId;
  final ValueChanged<int>? onChildSelected;

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  late int _selectedChildId;

  final List<Map<String, dynamic>> _children = [
    {'id': 1, 'name': 'Aarav Kumar', 'class': 'Grade 5 A'},
    {'id': 2, 'name': 'Diya Kumar', 'class': 'Grade 2 B'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.selectedChildId ?? 1;
  }

  @override
  void didUpdateWidget(covariant ParentAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedChildId != null && widget.selectedChildId != oldWidget.selectedChildId) {
      setState(() {
        _selectedChildId = widget.selectedChildId!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeChildId = _selectedChildId;
    final selectedChild = _children.firstWhere((c) => c['id'] == activeChildId, orElse: () => _children.first);
    final childIndex = _children.indexOf(selectedChild);
    final grade = getParentColorGrade(childIndex >= 0 ? childIndex : 0);

    final bg = isDark ? AppColors.darkBg : grade.screenBg;
    final surface = isDark ? AppColors.darkSurface : grade.cardBg;
    final textColor = isDark ? AppColors.darkText : grade.textMain;
    final mutedColor = isDark ? AppColors.darkMuted : grade.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : grade.cardBorder;

    // Days in October 2026 simulation
    final daysInMonth = List.generate(31, (i) {
      final day = i + 1;
      final date = DateTime(2026, 10, day);
      final isSunday = date.weekday == DateTime.sunday;
      String status = 'present';
      if (isSunday) {
        status = 'holiday';
      } else if (day > 12) {
        status = 'future';
      } else if (day == 5) {
        status = 'absent';
      } else if (day == 9) {
        status = 'late';
      }
      return {'day': day, 'weekday': date.weekday, 'status': status};
    });

    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text('Monthly calendar & presence statistics for ${selectedChild['name']}', style: TextStyle(fontSize: 11, color: mutedColor)),
          ],
        ),
        const SizedBox(height: 12),

        // Child Switcher Chips
        Row(
          children: _children.map((child) {
            final isSelected = child['id'] == activeChildId;
            final index = _children.indexOf(child);
            final grade = getParentColorGrade(index >= 0 ? index : 0);

            final childBg = grade.cardBg;
            final childText = grade.accentText;
            final childBorder = grade.cardBorder;

            final darkBg = AppColors.darkPrimarySoft;
            final darkText = const Color(0xFFA3A0FB);
            final darkBorder = const Color(0xFF3B82F6);

            return GestureDetector(
              onTap: () {
                setState(() => _selectedChildId = child['id']);
                widget.onChildSelected?.call(child['id']);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? darkBg : childBg)
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? darkBorder : childBorder)
                        : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDark ? darkBorder : childBorder).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? darkText : childText,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${child['name']} (${child['class']})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? (isDark ? darkText : childText) : (isDark ? AppColors.darkMuted : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // KPI Cards Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Presence Rate', style: TextStyle(fontSize: 10, color: mutedColor)),
                    const SizedBox(height: 2),
                    const Text('92%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A8E63), fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Present Days', style: TextStyle(fontSize: 10, color: mutedColor)),
                    const SizedBox(height: 2),
                    Text('10 / 12', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absences', style: TextStyle(fontSize: 10, color: mutedColor)),
                    const SizedBox(height: 2),
                    const Text('1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dangerText, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Month Calendar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('October 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                  Text('Academic Session 2025-26', style: TextStyle(fontSize: 11, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 14),
              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(day, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Calendar Grid (31 days)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daysInMonth.map((d) {
                  final dayNum = d['day'] as int;
                  final status = d['status'] as String;

                  Color cellBg;
                  Color cellText;

                  if (status == 'present') {
                    cellBg = const Color(0xFFDEF7EC);
                    cellText = const Color(0xFF03543F);
                  } else if (status == 'absent') {
                    cellBg = const Color(0xFFFDE8E8);
                    cellText = const Color(0xFF9B1C1C);
                  } else if (status == 'late') {
                    cellBg = const Color(0xFFFEF3C7);
                    cellText = const Color(0xFF854D0E);
                  } else if (status == 'holiday') {
                    cellBg = isDark ? AppColors.darkSunken : const Color(0xFFF1F5F9);
                    cellText = mutedColor;
                  } else {
                    // future
                    cellBg = isDark ? const Color(0xFF1E1F30) : grade.innerCardBg;
                    cellText = mutedColor.withOpacity(0.5);
                  }

                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cellBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cellText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 14,
                children: [
                  _buildLegendDot('Present', const Color(0xFF0E9F6E), textColor),
                  _buildLegendDot('Absent', AppColors.dangerText, textColor),
                  _buildLegendDot('Late', const Color(0xFFD97706), textColor),
                  _buildLegendDot('Holiday', mutedColor, textColor),
                ],
              ),
            ],
          ),
        ),
        const TaarroFooter(),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Attendance Record'),
        backgroundColor: AppColors.primaryAlt,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildLegendDot(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }
}
