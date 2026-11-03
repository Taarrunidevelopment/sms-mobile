enum AppRole { parent, admin, teacher, accountant }
enum ActiveStatus { active, inactive }
enum StudentStatus { active, left, transferred, graduated, inactive }
enum Gender { male, female, other }
enum AttendanceStatus { present, absent, late }
enum FeeStatus { paid, partial, unpaid }
enum SubmissionStatus { pending, submitted, overdue }
enum AcademicYearStatus { upcoming, active, archived }
enum PromotionAction { promoted, retained, graduated, transferred, left, inactive }

class Session {
  const Session({
    required this.userId,
    required this.role,
    required this.phone,
    required this.schoolId,
    required this.userName,
  });
  final int userId;
  final AppRole role;
  final String phone;
  final int schoolId;
  final String userName;
}

class ParentChild {
  const ParentChild({
    required this.id,
    required this.name,
    this.className,
    required this.admissionNo,
    this.rollNumber,
    this.classId,
  });
  final int id;
  final String name;
  final String? className;
  final String admissionNo;
  final String? rollNumber;
  final int? classId;
}

class Assignment {
  Assignment({
    required this.id,
    required this.classId,
    this.className,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    this.description,
    required this.dueDate,
    this.createdById = 1,
    this.createdByName,
    this.attachmentUrl,
    this.attachmentName,
    required this.submittedCount,
    this.totalCount = 30,
    int? totalStudents,
    this.hasOverdue = false,
  }) : totalStudents = totalStudents ?? totalCount;
  final int id;
  final int classId;
  final String? className;
  final int subjectId;
  final String subjectName;
  String title;
  String? description;
  String dueDate;
  final int createdById;
  final String? createdByName;
  final String? attachmentUrl;
  final String? attachmentName;
  int submittedCount;
  final int totalCount;
  final int totalStudents;
  final bool hasOverdue;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.readAt,
    required this.createdAt,
  });
  final int id;
  final String type;
  final String title;
  final String body;
  final int? relatedId;
  DateTime? readAt;
  final DateTime createdAt;
}

class Grade { const Grade({required this.id, required this.name, required this.subjectCount, required this.classCount, this.termCount = 0}); final int id; final String name; final int subjectCount; final int classCount; final int termCount; }
class GradeTerm { const GradeTerm({required this.id, required this.name, required this.gradeId}); final int id; final String name; final int gradeId; }
class Subject { const Subject({required this.id, required this.name, required this.gradeId}); final int id; final String name; final int gradeId; }
class SyllabusVersion { const SyllabusVersion({required this.id, this.subjectId, this.versionNum = 1, String? version, String? title, required this.content, this.fileUrl, this.fileName, this.createdByName = 'Academic Faculty', DateTime? createdAt, DateTime? uploadedAt,}) : title = title ?? version ?? 'Syllabus Revision'; final int id; final int? subjectId; final int versionNum; final String title; final String content; final String? fileUrl; final String? fileName; final String createdByName; }
class ClassRoom { const ClassRoom({required this.id, required this.gradeId, required this.section, required this.academicYearId, this.isArchived = false}); final int id; final int gradeId; final String section; final int academicYearId; final bool isArchived; }
class FacultyAssignment { const FacultyAssignment({required this.classId, required this.subjectId, required this.teacherUserId}); final int classId; final int subjectId; final int teacherUserId; }
class StaffMember { const StaffMember({required this.id, required this.name, required this.phone, required this.role, required this.status}); final int id; final String name; final String phone; final AppRole role; final ActiveStatus status; }
class Student { const Student({required this.id, required this.name, required this.admissionNo, required this.classId, required this.status}); final int id; final String name; final String admissionNo; final int classId; final StudentStatus status; }
class AttendanceRosterEntry { const AttendanceRosterEntry({required this.studentId, required this.name, required this.status}); final int studentId; final String name; final AttendanceStatus status; }
class Exam { const Exam({required this.id, required this.name, required this.term, required this.examDate, this.maxMarks}); final int id; final String name; final String term; final String examDate; final int? maxMarks; }
class FeeStructure { const FeeStructure({required this.id, required this.classId, required this.term, required this.amount, this.dueDate = '2026-09-15'}); final int id; final int classId; final String term; final num amount; final String dueDate; }
class FeeRosterEntry { const FeeRosterEntry({required this.studentId, required this.name, required this.amountPaid, required this.amount, required this.status}); final int studentId; final String name; final num amountPaid; final num amount; final FeeStatus status; }
class Period { const Period({required this.id, required this.order, required this.label, required this.isBreak, required this.start, required this.end}); final int id; final int order; final String label; final bool isBreak; final String start; final String end; }
class TimetableEntry { const TimetableEntry({required this.id, required this.classId, required this.dayOfWeek, required this.periodId, required this.subjectId}); final int id; final int classId; final int dayOfWeek; final int periodId; final int subjectId; }
class AcademicYear { const AcademicYear({required this.id, required this.name, required this.startDate, required this.endDate}); final int id; final int name; final String startDate; final String endDate; }
