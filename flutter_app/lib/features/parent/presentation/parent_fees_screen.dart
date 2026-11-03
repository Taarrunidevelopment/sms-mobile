import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';

class ParentFeesScreen extends StatefulWidget {
  const ParentFeesScreen({
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
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  late int _selectedChildId;

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
  void didUpdateWidget(covariant ParentFeesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedChildId != null && widget.selectedChildId != oldWidget.selectedChildId) {
      setState(() {
        _selectedChildId = widget.selectedChildId!;
      });
    }
  }

  void _openPaySheet(String term, num balance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final activeChildId = _selectedChildId;
        final selChild = _children.firstWhere((c) => c['id'] == activeChildId, orElse: () => _children.first);
        final cIndex = _children.indexOf(selChild);
        final grade = getParentColorGrade(cIndex >= 0 ? cIndex : 0);

        final sheetBg = isDark ? AppColors.darkSurface : grade.screenBg;
        final textColor = isDark ? AppColors.darkText : grade.textMain;
        final inputBg = isDark ? AppColors.darkSunken : grade.innerCardBg;
        final borderColor = isDark ? AppColors.darkBorder : grade.cardBorder;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Pay Tuition Fee: $term', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount to Pay:', style: TextStyle(fontSize: 13, color: textColor)),
                      Text(AppFormatters.formatCurrency(balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A8E63), fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A8E63),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee payment completed successfully!')));
                    },
                    child: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final feeItems = [
      {'term': 'Term 1 Tuition Fee', 'amount': 15000, 'paid': 15000, 'balance': 0, 'status': 'PAID', 'due': '2026-06-30'},
      {'term': 'Term 2 Tuition Fee', 'amount': 15000, 'paid': 9000, 'balance': 6000, 'status': 'PARTIAL', 'due': '2026-10-31'},
      {'term': 'Term 3 Tuition Fee', 'amount': 15000, 'paid': 0, 'balance': 15000, 'status': 'UNPAID', 'due': '2027-01-31'},
    ];

    final totalOutstanding = feeItems.fold<num>(0, (sum, i) => sum + (i['balance'] as num));

    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuition & Fee Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text('Academic fee structures & receipts for ${selectedChild['name']}', style: TextStyle(fontSize: 11, color: mutedColor)),
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

        // Total Outstanding Hero Card (Matching React gradient & typography)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grade.heroGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: grade.heroGradientColors.first.withOpacity(isDark ? 0.4 : 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL OUTSTANDING BALANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppFormatters.formatCurrency(totalOutstanding),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Academic session 2025-26',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Invoices List Section
        ...feeItems.map((f) {
          final balance = f['balance'] as num;
          final status = f['status'] as String;
          final isPaid = status == 'PAID';
          final isPartial = status == 'PARTIAL';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f['term']} Tuition Fee',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Due date: ${f['due']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFDEF7EC)
                            : isPartial
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isPaid
                              ? const Color(0xFF03543F)
                              : isPartial
                                  ? const Color(0xFF854D0E)
                                  : const Color(0xFF9B1C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Breakdown Inner Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF17161F) : grade.innerCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : grade.cardBorder.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Term Fee:', style: TextStyle(fontSize: 11, color: mutedColor)),
                          Text(
                            AppFormatters.formatCurrency(f['amount'] as num),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount Paid:', style: TextStyle(fontSize: 11, color: mutedColor)),
                          Text(
                            AppFormatters.formatCurrency(f['paid'] as num),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(
                          height: 1,
                          color: isDark ? AppColors.darkBorder : grade.cardBorder.withOpacity(0.5),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance Due:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            AppFormatters.formatCurrency(balance),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: balance > 0
                                  ? (isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48))
                                  : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pay Balance Button (matching React style)
                if (balance > 0) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF7C3AED) : grade.accentBg,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _openPaySheet(f['term'] as String, balance),
                      icon: const Icon(Icons.credit_card_rounded, size: 16),
                      label: Text(
                        'Pay Balance (${AppFormatters.formatCurrency(balance)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
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
        title: const Text('Fee Invoices'),
        backgroundColor: AppColors.primaryAlt,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
