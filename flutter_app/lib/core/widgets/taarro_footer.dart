import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TaarroFooter extends StatelessWidget {
  const TaarroFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Center(
        child: Text(
          'www.taarro.com',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
