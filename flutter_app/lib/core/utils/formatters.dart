abstract final class AppFormatters {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String formatCurrency(num amount) {
    final isNegative = amount < 0;
    final absVal = amount.abs().round();
    final str = absVal.toString();
    if (str.length <= 3) {
      return '${isNegative ? "-₹" : "₹"}$str';
    }
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    final formatted = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '${isNegative ? "-₹" : "₹"}$formatted,$lastThree';
  }

  static String normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.length == 10) {
      return '+91$digits';
    }
    return input.trim();
  }

  static bool isValidPhone(String phone) {
    final norm = normalizePhone(phone);
    if (!norm.startsWith('+91')) return false;
    final digits = norm.substring(3);
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  static String formatPhone(String phone) {
    final norm = normalizePhone(phone);
    if (norm.startsWith('+91') && norm.length == 13) {
      return '+91 ${norm.substring(3, 8)} ${norm.substring(8)}';
    }
    return norm;
  }

  static String formatDate(dynamic dateInput) {
    if (dateInput == null) return '—';
    if (dateInput is DateTime) {
      final month = _months[(dateInput.month - 1).clamp(0, 11)];
      return '${dateInput.day} $month ${dateInput.year}';
    }
    final isoDate = dateInput.toString().trim();
    if (isoDate.isEmpty) return '—';
    try {
      final clean = isoDate.contains('T') ? isoDate.split('T')[0] : isoDate;
      final parts = clean.split('-').map(int.parse).toList();
      if (parts.length >= 3) {
        final month = _months[(parts[1] - 1).clamp(0, 11)];
        return '${parts[2]} $month ${parts[0]}';
      }
    } catch (_) {}
    return isoDate;
  }

  static String calculateGrade(num marks, num maxMarks) {
    if (maxMarks <= 0) return 'F';
    final pct = (marks / maxMarks) * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return 'SP';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
