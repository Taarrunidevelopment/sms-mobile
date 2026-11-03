import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../domain/entities/models.dart';
import '../../profile/presentation/profile_screen.dart';
import 'parent_assignments_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_marks_screen.dart';
import 'parent_notifications_screen.dart';
import '../../../core/utils/parent_theme.dart';
import '../../../core/widgets/taarro_footer.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key, required this.session});
  final Session session;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentTabIndex = 0;
  int _selectedChildId = 1; // 1: Aarav, 2: Diya
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _children = [
    {'id': 1, 'name': 'Aarav Kumar', 'class': 'Grade 5 A', 'roll': '7', 'admission': 'SPS-2025-0001'},
    {'id': 2, 'name': 'Diya Kumar', 'class': 'Grade 2 B', 'roll': '12', 'admission': 'SPS-2025-0002'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavigateTab(int index) {
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedChild = _children.firstWhere((c) => c['id'] == _selectedChildId, orElse: () => _children.first);
    final childIndex = _children.indexOf(selectedChild);
    final grade = getParentColorGrade(childIndex >= 0 ? childIndex : 0);

    final cardBg = isDark ? AppColors.darkSurface : grade.cardBg;
    final borderColor = isDark ? AppColors.darkBorder : grade.cardBorder;
    final inkColor = isDark ? AppColors.darkInk : grade.textMain;
    final mutedColor = isDark ? AppColors.darkMuted : grade.textMuted;
    final sunkenBg = isDark ? AppColors.darkSunken : grade.subtleBg;

    Widget bodyWidget;
    switch (_currentTabIndex) {
      case 1:
        bodyWidget = ParentAssignmentsScreen(
          session: widget.session,
          selectedChildId: _selectedChildId,
          onChildSelected: (id) => setState(() => _selectedChildId = id),
        );
        break;
      case 2:
        bodyWidget = ParentAttendanceScreen(
          session: widget.session,
          selectedChildId: _selectedChildId,
          onChildSelected: (id) => setState(() => _selectedChildId = id),
        );
        break;
      case 3:
        bodyWidget = ParentMarksScreen(
          session: widget.session,
          selectedChildId: _selectedChildId,
          onChildSelected: (id) => setState(() => _selectedChildId = id),
        );
        break;
      case 4:
        bodyWidget = ParentFeesScreen(
          session: widget.session,
          selectedChildId: _selectedChildId,
          onChildSelected: (id) => setState(() => _selectedChildId = id),
        );
        break;
      case 0:
      default:
        bodyWidget = _buildHomeDashboard(
          cardBg: cardBg,
          borderColor: borderColor,
          inkColor: inkColor,
          mutedColor: mutedColor,
          sunkenBg: sunkenBg,
          isDark: isDark,
        );
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : grade.screenBg,
      appBar: AppHeader(
        session: widget.session,
        onOpenNotifications: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentNotificationsScreen(
                session: widget.session,
                selectedChildId: _selectedChildId,
              ),
            ),
          );
        },
        onOpenProfile: () {
          final selChild = _children.firstWhere((c) => c['id'] == _selectedChildId, orElse: () => _children.first);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                session: Session(
                  userId: selChild['id'],
                  role: AppRole.parent,
                  phone: widget.session.phone,
                  schoolId: widget.session.schoolId,
                  userName: selChild['name'],
                ),
              ),
            ),
          );
        },
      ),
      body: bodyWidget,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.menu_book_rounded, 'Homework'),
                _buildNavItem(2, Icons.calendar_today_rounded, 'Attendance'),
                _buildNavItem(3, Icons.military_tech_rounded, 'Exams'),
                _buildNavItem(4, Icons.account_balance_wallet_rounded, 'Fees'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childIndex = _children.indexWhere((c) => c['id'] == _selectedChildId);
    final safeIndex = childIndex >= 0 ? childIndex : 0;
    final grade = getParentColorGrade(safeIndex);

    final activeBg = isDark ? const Color(0xFF262445) : grade.subtleBg;
    final activeTextColor = isDark ? const Color(0xFFA3A0FB) : grade.textMain;
    final inactiveTextColor = isDark ? AppColors.darkMuted : AppColors.muted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeTextColor : inactiveTextColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeDashboard({
    required Color cardBg,
    required Color borderColor,
    required Color inkColor,
    required Color mutedColor,
    required Color sunkenBg,
    required bool isDark,
  }) {
    final selectedChild = _children.firstWhere(
      (c) => c['id'] == _selectedChildId,
      orElse: () => _children.first,
    );
    final isAarav = selectedChild['id'] == 1;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Switcher Chips
          Row(
            children: _children.map((child) {
              final isSelected = child['id'] == _selectedChildId;
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
                        child['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? (isDark ? darkText : childText) : (isDark ? AppColors.darkMuted : const Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${child['class']})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? (isDark ? darkText.withOpacity(0.85) : childText.withOpacity(0.85)) : (isDark ? AppColors.darkMuted : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 1. Upcoming Homework Section
          _buildSectionCard(
            title: 'Upcoming Homework',
            subtitle: 'Active homework for ${selectedChild['name']}',
            actionText: 'All tasks',
            onAction: () => _onNavigateTab(1),
            cardBg: cardBg,
            borderColor: borderColor,
            inkColor: inkColor,
            mutedColor: mutedColor,
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sunkenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAarav
                              ? 'Fractions & Word Problems'
                              : 'Phonics & Reading Practice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: inkColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAarav
                              ? 'Mathematics · Due 18 Oct'
                              : 'English · Due 19 Oct',
                          style: TextStyle(fontSize: 11, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF6E4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFBE9B6)),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA16207),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Attendance Summary Section
          _buildSectionCard(
            title: 'Attendance This Month',
            subtitle: "${selectedChild['name']}'s attendance rate",
            actionText: 'Calendar',
            onAction: () => _onNavigateTab(2),
            cardBg: cardBg,
            borderColor: borderColor,
            inkColor: inkColor,
            mutedColor: mutedColor,
            content: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCDEFE0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAarav ? '94%' : '96%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A8E63),
                        ),
                      ),
                      const Text(
                        'PRESENT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A8E63),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDayStatus('Mon', 'P', sunkenBg, borderColor, mutedColor, isDark),
                      _buildDayStatus('Tue', 'P', sunkenBg, borderColor, mutedColor, isDark),
                      _buildDayStatus('Wed', 'P', sunkenBg, borderColor, mutedColor, isDark),
                      _buildDayStatus('Thu', 'L', sunkenBg, borderColor, mutedColor, isDark),
                      _buildDayStatus('Fri', 'P', sunkenBg, borderColor, mutedColor, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Fee Dues & Balance Section
          _buildSectionCard(
            title: 'Fee Dues & Balance',
            subtitle: 'Term tuition payment status',
            actionText: 'Invoices',
            onAction: () => _onNavigateTab(4),
            cardBg: cardBg,
            borderColor: borderColor,
            inkColor: inkColor,
            mutedColor: mutedColor,
            content: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkButter : const Color(0xFFFEF5DB).withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFFBE9B6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OUTSTANDING BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkButterInk : const Color(0xFFB8860B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAarav ? '₹6,000' : '₹0',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: inkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAarav ? 'Due Date: 15 Nov 2026' : 'All term fees cleared',
                        style: TextStyle(fontSize: 10, color: mutedColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAarav ? const Color(0xFFFEF6E4) : AppColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAarav ? const Color(0xFFFBE9B6) : const Color(0xFFCDEFE0),
                      ),
                    ),
                    child: Text(
                      isAarav ? 'Partial Dues' : 'Paid in Full',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAarav ? const Color(0xFFA16207) : AppColors.successText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Latest Exam Results Section
          _buildSectionCard(
            title: 'Unit Test 2',
            subtitle: 'Published results for Term 2',
            actionText: 'Report Card',
            onAction: () => _onNavigateTab(3),
            cardBg: cardBg,
            borderColor: borderColor,
            inkColor: inkColor,
            mutedColor: mutedColor,
            content: Column(
              children: [
                _buildExamScoreRow(
                  subject: 'Mathematics',
                  score: isAarav ? '23/25' : '24/25',
                  grade: isAarav ? 'Grade A' : 'Grade A+',
                  sunkenBg: sunkenBg,
                  borderColor: borderColor,
                  inkColor: inkColor,
                ),
                const SizedBox(height: 8),
                _buildExamScoreRow(
                  subject: isAarav ? 'Science' : 'English',
                  score: isAarav ? '21/25' : '25/25',
                  grade: isAarav ? 'Grade A' : 'Grade A+',
                  sunkenBg: sunkenBg,
                  borderColor: borderColor,
                  inkColor: inkColor,
                ),
                const SizedBox(height: 8),
                _buildExamScoreRow(
                  subject: isAarav ? 'English' : 'Hindi',
                  score: isAarav ? '24/25' : '23/25',
                  grade: 'Grade A',
                  sunkenBg: sunkenBg,
                  borderColor: borderColor,
                  inkColor: inkColor,
                ),
              ],
            ),
          ),
          const TaarroFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required Widget content,
    required Color cardBg,
    required Color borderColor,
    required Color inkColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
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
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onAction,
                child: Row(
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildExamScoreRow({
    required String subject,
    required String score,
    required String grade,
    required Color sunkenBg,
    required Color borderColor,
    required Color inkColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sunkenBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            subject,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: inkColor),
          ),
          Row(
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: inkColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EFFD),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4DEFA)),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B5ECC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatus(String day, String status, Color bg, Color border, Color muted, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201F2C) : bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: muted)),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: status == 'P' ? const Color(0xFF1A8E63) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
