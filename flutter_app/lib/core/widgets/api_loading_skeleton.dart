import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ApiLoadingSkeleton extends StatelessWidget {
  const ApiLoadingSkeleton({super.key, this.variant = 'list'});
  final String variant;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (variant == 'inline') {
      return Row(children: [
        const SkeletonBlock(width: 34, height: 34, radius: 17),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBlock(width: 150, height: 12),
          const SizedBox(height: 8),
          SkeletonBlock(width: MediaQuery.sizeOf(context).width * .38, height: 9),
        ])),
      ]);
    }

    if (variant == 'profile') {
      return Column(children: [
        const SizedBox(height: 24),
        const SkeletonBlock(width: 84, height: 84, radius: 42),
        const SizedBox(height: 14),
        const SkeletonBlock(width: 170, height: 18),
        const SizedBox(height: 8),
        const SkeletonBlock(width: 120, height: 11),
        const SizedBox(height: 24),
        _card(dark, 3),
        _card(dark, 3),
        _card(dark, 2),
      ]);
    }

    if (variant == 'attendance') {
      return Column(children: [
        _card(dark, 2, leading: true),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: _decoration(dark),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [SkeletonBlock(width: 20, height: 20, radius: 10), SkeletonBlock(width: 125, height: 14), SkeletonBlock(width: 20, height: 20, radius: 10)]),
            const SizedBox(height: 20),
            for (var row = 0; row < 5; row++) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (_) => const SkeletonBlock(width: 28, height: 28, radius: 7))),
              const SizedBox(height: 9),
            ],
          ]),
        ),
        _card(dark, 2),
      ]);
    }

    return Column(children: [
      _card(dark, 2),
      _card(dark, 3),
      _card(dark, 3),
    ]);
  }

  Widget _card(bool dark, int rows, {bool leading = false}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _decoration(dark),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (leading) ...[
            Row(children: const [SkeletonBlock(width: 42, height: 42, radius: 21), SizedBox(width: 12), Expanded(child: SkeletonBlock(width: 150, height: 14))]),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < rows; i++) ...[
            SkeletonBlock(width: i == 0 ? 145 : 205, height: i == 0 ? 12 : 9),
            if (i < rows - 1) const SizedBox(height: 11),
          ],
        ]),
      );

  BoxDecoration _decoration(bool dark) => BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.darkBorder : AppColors.border),
      );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, required this.width, required this.height, this.radius = 6});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSunken : AppColors.sunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
