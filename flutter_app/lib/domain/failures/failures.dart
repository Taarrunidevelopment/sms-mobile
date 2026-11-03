sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field});
  final String? field;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

final class DeletionBlockedFailure extends Failure {
  const DeletionBlockedFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

enum AuthErrorKind { invalid, locked, notRegistered, empty }

final class AuthFailure extends Failure {
  const AuthFailure(super.message, this.kind);
  final AuthErrorKind kind;
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
