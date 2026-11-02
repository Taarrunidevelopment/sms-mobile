import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/parent_theme.dart';

String schoolTimeZone = 'UTC';

JsonMap asJsonMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String readableError(Object error) => error.toString();

String initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String apiDate(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return '—';
  final date = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
  return date == null ? raw : DateFormat('d MMM yyyy').format(date);
}

String apiTimestamp(dynamic value) {
  final raw = value?.toString() ?? '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.isEmpty ? '—' : raw;
  try {
    return DateFormat('d MMM yyyy, h:mm a').format(tz.TZDateTime.from(parsed, tz.getLocation(schoolTimeZone)));
  } catch (_) {
    return raw;
  }
}

class ApiErrorPanel extends StatelessWidget {
  const ApiErrorPanel({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
            if (onRetry != null) IconButton(onPressed: onRetry, tooltip: 'Retry', icon: const Icon(Icons.refresh)),
          ]),
        ),
      );
}

class ParentEmptyCard extends StatelessWidget {
  const ParentEmptyCard({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
}

class ParentInfoCard extends StatelessWidget {
  const ParentInfoCard({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer))),
        ])),
      );
}

class ParentAvatar extends StatelessWidget {
  const ParentAvatar({super.key, required this.name, this.photoUrl, this.radius = 23, this.tint});
  final String name;
  final String? photoUrl;
  final double radius;
  final Color? tint;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: tint ?? Theme.of(context).colorScheme.primaryContainer,
        foregroundImage: photoUrl == null || photoUrl!.isEmpty ? null : NetworkImage(photoUrl!),
        child: Text(initials(name), style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onPrimaryContainer)),
      );
}

class ChildGradeAvatar extends StatelessWidget {
  const ChildGradeAvatar({super.key, required this.name, required this.index, this.imageUrl, this.radius = 23});
  final String name;
  final String? imageUrl;
  final int index;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final grade = getParentColorGrade(index);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      radius: radius,
      backgroundColor: dark ? AppColors.darkPrimarySoft : grade.subtleBg,
      foregroundImage: imageUrl == null || imageUrl!.isEmpty ? null : NetworkImage(imageUrl!),
      child: Text(initials(name), style: TextStyle(fontWeight: FontWeight.w800, color: dark ? AppColors.darkInk : grade.accentText)),
    );
  }
}

class ParentInfoRow extends StatelessWidget {
  const ParentInfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(width: 14),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ]),
      );
}

void showParentMessage(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
