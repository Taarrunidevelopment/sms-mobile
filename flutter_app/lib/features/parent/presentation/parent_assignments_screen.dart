import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';

class ParentAssignmentsScreen extends StatefulWidget {
  const ParentAssignmentsScreen({
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
  State<ParentAssignmentsScreen> createState() => _ParentAssignmentsScreenState();
}

class _ParentAssignmentsScreenState extends State<ParentAssignmentsScreen> {
  late int _selectedChildId;
  String _filter = 'all'; // all, pending, submitted, overdue

  final List<Map<String, dynamic>> _children = [
    {'id': 1, 'name': 'Aarav Kumar', 'class': 'Grade 5 A', 'classId': 9},
    {'id': 2, 'name': 'Diya Kumar', 'class': 'Grade 2 B', 'classId': 4},
  ];

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.selectedChildId ?? 1;
  }

  @override
  void didUpdateWidget(covariant ParentAssignmentsScreen oldWidget) {
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
    final allAssignments = <Assignment>[]; // Placeholder for backend data integration

    final filtered = allAssignments.where((a) {
      if (_filter == 'all') return true;
      final isSubmitted = a.submittedCount >= 20;
      final isOverdue = a.dueDate.compareTo('2026-10-12') < 0 && !isSubmitted;
      if (_filter == 'submitted') return isSubmitted;
      if (_filter == 'overdue') return isOverdue;
      if (_filter == 'pending') return !isSubmitted && !isOverdue;
      return true;
    }).toList();

    Widget body = Column(
      children: [
        // Header (if not embedded with app bar)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assignments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 2),
                  Text('Homework and projects for ${selectedChild['name']}', style: TextStyle(fontSize: 11, color: mutedColor)),
                ],
              ),
            ],
          ),
        ),

        // Child Switcher Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
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
        ),

        // Filter Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSunken : grade.innerCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                for (final tab in ['all', 'pending', 'submitted', 'overdue'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _filter == tab ? (isDark ? surface : grade.cardBg) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _filter == tab
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: _filter == tab ? FontWeight.bold : FontWeight.w600,
                            color: _filter == tab ? textColor : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Assignments List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No $_filter assignments found for ${selectedChild['name']}.',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  itemCount: filtered.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == filtered.length) {
                      return const TaarroFooter();
                    }
                    final item = filtered[idx];
                    final isSubmitted = item.submittedCount >= 20;
                    final isOverdue = item.dueDate.compareTo('2026-10-12') < 0 && !isSubmitted;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSunken : grade.subtleBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.subjectName,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA3A0FB) : grade.accentText, fontSize: 10),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSubmitted
                                          ? const Color(0xFFDEF7EC)
                                          : isOverdue
                                              ? const Color(0xFFFDE8E8)
                                              : (isDark ? const Color(0xFF382A13) : const Color(0xFFFEF3C7)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isSubmitted ? 'SUBMITTED' : isOverdue ? 'OVERDUE' : 'PENDING',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isSubmitted
                                            ? const Color(0xFF03543F)
                                            : isOverdue
                                                ? const Color(0xFF9B1C1C)
                                                : const Color(0xFF854D0E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Due: ${item.dueDate}', style: TextStyle(fontSize: 11, color: mutedColor, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                          if (item.description != null) ...[
                            const SizedBox(height: 4),
                            Text(item.description!, style: TextStyle(fontSize: 12, color: mutedColor, height: 1.3)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attachment, size: 14, color: mutedColor),
                              const SizedBox(width: 4),
                              Text('worksheet_assignment.pdf', style: TextStyle(fontSize: 10, color: mutedColor)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Tasks & Homework'),
        backgroundColor: AppColors.primaryAlt,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
