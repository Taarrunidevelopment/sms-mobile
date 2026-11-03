import '../entities/models.dart';

abstract interface class AuthRepository {
  Future<String> sendOtp(String phone);
  Future<Session> verify(String phone, String code);
  Future<void> logout();
  Future<Session?> currentSession();
}

abstract interface class GradeRepository {
  Future<List<Grade>> list();
  Future<Grade> create(String name);
  Future<Grade> rename(int id, String name);
  Future<void> delete(int id);
}

abstract interface class TermRepository {
  Future<List<GradeTerm>> listByGrade(int gradeId);
  Future<List<String>> listAllKnownTerms();
  Future<GradeTerm> create(int gradeId, String name);
  Future<List<GradeTerm>> addAll(int gradeId, List<String> names);
  Future<void> delete(int id);
}

abstract interface class SubjectRepository {
  Future<List<Subject>> listByGrade(int gradeId);
  Future<Subject> create(int gradeId, String name);
  Future<List<Subject>> addAll(int gradeId, List<String> names);
  Future<void> delete(int id);
}

abstract interface class SyllabusRepository {
  Future<List<SyllabusVersion>> list(int subjectId);
  Future<SyllabusVersion> create(int subjectId, String title, String content, {String? fileName});
}

abstract interface class ClassRepository {
  Future<List<ClassRoom>> list({bool includeArchived = false});
  Future<List<int>> listForTeacher(int userId);
  Future<ClassRoom> create(int gradeId, String section, int academicYearId);
  Future<ClassRoom> updateSection(int id, String section);
  Future<void> archive(int id);
  Future<void> unarchive(int id);
  Future<void> delete(int id);
  Future<List<FacultyAssignment>> getFaculty(int classId);
  Future<void> assignFaculty(int classId, int subjectId, int teacherUserId);
}

abstract interface class FacultyRepository {
  Future<List<FacultyAssignment>> list(int classId);
  Future<void> assign(int classId, int subjectId, int teacherUserId);
  Future<void> unassign(int classId, int subjectId, int teacherUserId);
  Future<void> setClassTeacher(int classId, int teacherUserId);
}

abstract interface class StaffRepository {
  Future<List<StaffMember>> list();
  Future<StaffMember> create(String name, String phone, AppRole role, {int? classId, int? subjectId});
  Future<StaffMember> update(int id, String name, String phone, AppRole role, {int? classId, int? subjectId});
  Future<void> activate(int id);
  Future<void> deactivate(int id);
  Future<void> delete(int id);
}

abstract interface class StudentRepository {
  Future<List<Student>> list({int? classId});
  Future<Student> create(Student student);
  Future<Student> update(int id, Student student);
  Future<void> activate(int id);
  Future<void> deactivate(int id);
  Future<void> delete(int id);
}

abstract interface class AttendanceRepository {
  Future<List<AttendanceRosterEntry>> roster(int classId, String date);
  Future<void> submit(int classId, String date, List<AttendanceRosterEntry> entries);
}

abstract interface class AssignmentRepository {
  Future<List<Assignment>> list({int? classId});
  Future<Assignment> create(int classId, int subjectId, String title, String description, String dueDate, {String? attachmentName});
  Future<Assignment> update(int id, String title, String description, String dueDate);
  Future<List<Map<String, dynamic>>> statuses(int assignmentId);
  Future<void> toggleStatus(int assignmentId, int studentId, SubmissionStatus status);
}

abstract interface class ExamRepository {
  Future<List<Exam>> list();
  Future<Exam> create(String name, String term, String examDate);
}

abstract interface class MarksRepository {
  Future<Map<String, dynamic>> sheet(int examId, int classId);
  Future<void> save(int examId, int classId, int subjectId, num maxMarks, List<Map<String, dynamic>> entries);
}

abstract interface class FeeRepository {
  Future<List<FeeStructure>> structures({int? classId});
  Future<FeeStructure> createStructure(int classId, String term, num amount, String dueDate);
  Future<List<FeeRosterEntry>> roster(int feeStructureId);
  Future<Map<String, dynamic>> recordPayment(int feeStructureId, int studentId, num amount);
}

abstract interface class PeriodRepository {
  Future<List<Period>> list();
  Future<Period> create(int order, String label, bool isBreak, String start, String end);
  Future<void> delete(int id);
}

abstract interface class TimetableRepository {
  Future<List<TimetableEntry>> entries(int classId);
  Future<TimetableEntry> saveSlot(int classId, int dayOfWeek, int periodId, int subjectId, {int? teacherUserId});
}

abstract interface class AcademicYearRepository {
  Future<List<AcademicYear>> list();
  Future<AcademicYear> create(String name, String startDate, String endDate);
}

abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<void> markRead(int id);
}

abstract interface class ParentRepository {
  Future<List<ParentChild>> children(String phone);
  Future<Map<String, dynamic>> overview(int studentId);
}
