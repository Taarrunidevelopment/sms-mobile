import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';

class ParentMarksScreen extends StatefulWidget {
  const ParentMarksScreen({
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
  State<ParentMarksScreen> createState() => _ParentMarksScreenState();
}

class _ParentMarksScreenState extends State<ParentMarksScreen> {
  late int _selectedChildId;
  int _activeExamId = 3; // Unit Test 2 default

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
  void didUpdateWidget(covariant ParentMarksScreen oldWidget) {
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
    final childIndex = _children.indexWhere((c) => c['id'] == activeChildId);
    final grade = getParentColorGrade(childIndex >= 0 ? childIndex : 0);

    final bg = isDark ? AppColors.darkBg : grade.screenBg;
    final surface = isDark ? AppColors.darkSurface : grade.cardBg;
    final textColor = isDark ? AppColors.darkText : grade.textMain;
    final mutedColor = isDark ? AppColors.darkMuted : grade.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : grade.cardBorder;
    final exams = <Exam>[]; // Placeholder for backend data integration
    final activeExam = exams.firstWhere((e) => e.id == _activeExamId, orElse: () => exams[0]);
    final maxMarks = activeExam.maxMarks ?? 25;

    final subjectMarks = [
      {'subject': 'Mathematics', 'score': (maxMarks * 0.92).round(), 'grade': 'A+'},
      {'subject': 'Science', 'score': (maxMarks * 0.88).round(), 'grade': 'A'},
      {'subject': 'English', 'score': (maxMarks * 0.84).round(), 'grade': 'A'},
      {'subject': 'Hindi', 'score': (maxMarks * 0.80).round(), 'grade': 'B+'},
      {'subject': 'Social Studies', 'score': (maxMarks * 0.76).round(), 'grade': 'B'},
    ];

    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exams & Report Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text('Academic evaluation for ${selectedChild['name']}', style: TextStyle(fontSize: 11, color: mutedColor)),
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
        const SizedBox(height: 12),

        // Exam Tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSunken : grade.innerCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: exams.map((ex) {
              final isSelected = ex.id == _activeExamId;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeExamId = ex.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? surface : grade.cardBg) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isSelected
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
                      ex.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? textColor : mutedColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Exam Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activeExam.name} (${activeExam.term})',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text('Exam Date: ${activeExam.examDate}', style: TextStyle(fontSize: 11, color: mutedColor, fontFamily: 'monospace')),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282548) : grade.subtleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? const Color(0xFF6B5ECC) : grade.accentText)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'SUBJECT SCORES',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),

        // Subject Scores Breakdown
        ...subjectMarks.map((sm) {
          final score = sm['score'] as int;
          final pct = (score / maxMarks).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? surface : grade.innerCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sm['subject'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    Row(
                      children: [
                        Text('$score / $maxMarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor, fontFamily: 'monospace')),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEF7EC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(sm['grade'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF03543F))),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: isDark ? AppColors.darkSunken : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF6B5ECC) : grade.accentBg),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }),
        const TaarroFooter(),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Exams & Marks'),
        backgroundColor: AppColors.primaryAlt,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
