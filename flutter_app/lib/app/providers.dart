import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/models.dart';
import '../domain/repositories/repositories.dart';
import '../core/network/api_client.dart';

// Repository Providers - Using ApiClient directly for now
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // We'll implement a proper repository later. For now just Auth.
  throw UnimplementedError();
});

final gradeRepositoryProvider = Provider<GradeRepository>((ref) => throw UnimplementedError());
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) => throw UnimplementedError());
final termRepositoryProvider = Provider<TermRepository>((ref) => throw UnimplementedError());
final classRepositoryProvider = Provider<ClassRepository>((ref) => throw UnimplementedError());
final staffRepositoryProvider = Provider<StaffRepository>((ref) => throw UnimplementedError());
final studentRepositoryProvider = Provider<StudentRepository>((ref) => throw UnimplementedError());
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => throw UnimplementedError());
final feeRepositoryProvider = Provider<FeeRepository>((ref) => throw UnimplementedError());
final syllabusRepositoryProvider = Provider<SyllabusRepository>((ref) => throw UnimplementedError());

// State Notifiers
final currentSessionProvider = StateProvider<Session?>((ref) => null);
final selectedChildIdProvider = StateProvider<int>((ref) => 1);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
