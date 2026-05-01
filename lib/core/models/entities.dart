enum UserRole { admin, teacher, student }

class Department {
  Department({required this.id, required this.name});

  final int id;
  final String name;
}

class Course {
  Course({
    required this.id,
    required this.name,
    required this.credits,
    this.isActive = false,
  });

  final int id;
  final String name;
  final int credits;
  bool isActive;
}

class UserAccount {
  UserAccount({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.department,
    this.rollNumber,
    this.isActive = false,
    this.hasFaceRegistered = false,
    this.profilePicture,
  });

  final int id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? department;
  final String? rollNumber;
  final String? profilePicture;
  bool isActive;
  bool hasFaceRegistered;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.recordedAt,
    required this.method,
  });

  final int id;
  final int studentId;
  final int courseId;
  final DateTime recordedAt;
  final String method;
}

class Session {
  Session({required this.role, required this.email, this.userId});

  final UserRole role;
  final String email;
  final int? userId;
}
