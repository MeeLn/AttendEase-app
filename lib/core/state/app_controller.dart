import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/face_recognition_service.dart';
import '../../services/local_database_service.dart';
import '../models/entities.dart';

class AppController extends ChangeNotifier {
  AppController() {
    unawaited(_initialize());
  }

  final LocalDatabaseService _database = LocalDatabaseService.instance;

  Session? session;
  bool isReady = false;
  String? initializationError;

  List<Department> departments = [];
  List<Course> courses = [];
  List<UserAccount> users = [];
  List<AttendanceRecord> attendance = [];

  UserAccount? get currentUser {
    final current = session;
    if (current == null || current.userId == null) {
      return null;
    }
    return users.cast<UserAccount?>().firstWhere(
      (user) => user!.id == current.userId,
      orElse: () => null,
    );
  }

  List<UserAccount> get students =>
      users.where((user) => user.role == UserRole.student).toList();

  List<UserAccount> get teachers =>
      users.where((user) => user.role == UserRole.teacher).toList();

  List<Course> get activeCourses =>
      courses.where((course) => course.isActive).toList();

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail == 'admin@admin.com' && password == 'admin123') {
      session = Session(role: UserRole.admin, email: normalizedEmail);
      notifyListeners();
      return null;
    }

    final user = await _database.findUserByCredentials(
      email: normalizedEmail,
      password: password,
    );

    if (user == null) {
      return 'Login failed. Check your email and password.';
    }

    if (!user.isActive) {
      return 'This account is awaiting admin approval.';
    }

    final registered = user.role == UserRole.student
        ? await FaceRecognitionService.hasRegisteredFace(_faceUserKey(user))
        : user.hasFaceRegistered;
    if (user.role == UserRole.student && user.hasFaceRegistered != registered) {
      await _database.updateUserFaceRegistered(user.id, registered);
      await _reloadData();
    }

    session = Session(role: user.role, email: user.email, userId: user.id);
    notifyListeners();
    return null;
  }

  void logout() {
    session = null;
    notifyListeners();
  }

  Future<String?> registerStudent({
    required String firstName,
    required String lastName,
    required String department,
    required String rollNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final validation = _validateCommonRegistration(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (validation != null) {
      return validation;
    }
    if (department.trim().isEmpty) {
      return 'Please select a department.';
    }
    if (rollNumber.trim().isEmpty) {
      return 'Roll number is required.';
    }
    if (await _database.emailExists(email)) {
      return 'Email already registered.';
    }

    await _database.insertStudent(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      department: department.trim(),
      rollNumber: rollNumber.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _reloadData();
    notifyListeners();
    return null;
  }

  Future<String?> registerTeacher({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final validation = _validateCommonRegistration(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (validation != null) {
      return validation;
    }
    if (await _database.emailExists(email)) {
      return 'Email already registered.';
    }

    await _database.insertTeacher(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _reloadData();
    notifyListeners();
    return null;
  }

  Future<String?> addDepartment(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'Department name is required.';
    }
    if (await _database.departmentExists(normalized)) {
      return 'Department already exists.';
    }
    await _database.insertDepartment(normalized);
    await _reloadData();
    notifyListeners();
    return null;
  }

  Future<void> deleteDepartment(int departmentId) async {
    await _database.deleteDepartment(departmentId);
    await _reloadData();
    notifyListeners();
  }

  Future<String?> addCourse({
    required String name,
    required String creditsText,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'Course name is required.';
    }
    final credits = int.tryParse(creditsText.trim());
    if (credits == null || credits <= 0) {
      return 'Credits must be a positive number.';
    }
    if (await _database.courseExists(normalized)) {
      return 'Course already exists.';
    }
    await _database.insertCourse(name: normalized, credits: credits);
    await _reloadData();
    notifyListeners();
    return null;
  }

  Future<void> deleteCourse(int courseId) async {
    await _database.deleteCourse(courseId);
    await _reloadData();
    notifyListeners();
  }

  Future<void> toggleUserStatus(int userId) async {
    final user = users.firstWhere((candidate) => candidate.id == userId);
    await _database.updateUserStatus(userId, !user.isActive);
    await _reloadData();
    notifyListeners();
  }

  Future<void> deleteUser(int userId) async {
    await _database.deleteUser(userId);
    await _reloadData();
    notifyListeners();
  }

  Future<String?> updateUserProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    String? department,
    String? rollNumber,
    String? newPassword,
    String? confirmPassword,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty || email.trim().isEmpty) {
      return 'First name, last name and email are required.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      if (newPassword.length < 6) return 'Password must be at least 6 characters.';
      if (newPassword != confirmPassword) return 'Passwords do not match.';
    }
    await _database.updateUserProfile(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      department: department,
      rollNumber: rollNumber,
      newPassword: (newPassword != null && newPassword.isNotEmpty) ? newPassword : null,
    );
    await _reloadData();
    notifyListeners();
    return null;
  }

  Future<void> toggleCourseStatus(int courseId) async {
    final course = courses.firstWhere((candidate) => candidate.id == courseId);
    await _database.updateCourseStatus(courseId, !course.isActive);
    await _reloadData();
    notifyListeners();
  }

  Future<String?> registerFaceForCurrentStudent() async {
    final user = currentUser;
    if (user == null || user.role != UserRole.student) {
      return 'Student session not found.';
    }
    final result = await FaceRecognitionService.registerFace(
      _faceUserKey(user),
    );
    if (!result.success) {
      return result.message;
    }
    await _database.updateUserFaceRegistered(user.id, result.faceRegistered);
    await _reloadData();
    notifyListeners();
    return result.message;
  }

  Future<String?> markAttendanceForCurrentStudent(int courseId) async {
    final user = currentUser;
    if (user == null || user.role != UserRole.student) {
      return 'Student session not found.';
    }
    if (!user.hasFaceRegistered) {
      return 'Register your face profile before taking attendance.';
    }
    final verificationResult = await FaceRecognitionService.recognizeFace(
      _faceUserKey(user),
    );
    if (!verificationResult.success) {
      return verificationResult.message;
    }
    return _markAttendance(
      studentId: user.id,
      courseId: courseId,
      method: 'Face verified',
    );
  }

  Future<String?> markAttendanceForStudent({
    required int studentId,
    required int courseId,
  }) async {
    return _markAttendance(
      studentId: studentId,
      courseId: courseId,
      method: 'Teacher marked',
    );
  }

  List<AttendanceRecord> recordsForStudent(int studentId) {
    final records =
        attendance.where((record) => record.studentId == studentId).toList()
          ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return records;
  }

  List<AttendanceRecord> recordsForCourse(int courseId) {
    final records =
        attendance.where((record) => record.courseId == courseId).toList()
          ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return records;
  }

  UserAccount studentById(int studentId) {
    return users.firstWhere((user) => user.id == studentId);
  }

  Course courseById(int courseId) {
    return courses.firstWhere((course) => course.id == courseId);
  }

  int attendanceCountForStudent(int studentId) {
    return attendance.where((record) => record.studentId == studentId).length;
  }

  int attendanceCountForCourse(int courseId) {
    return attendance.where((record) => record.courseId == courseId).length;
  }

  Future<void> _initialize() async {
    try {
      await _database.initialize();
      await _database.seedIfEmpty();
      await _reloadData();
      isReady = true;
      initializationError = null;
    } catch (error) {
      initializationError = error.toString();
      isReady = true;
    }
    notifyListeners();
  }

  Future<void> _reloadData() async {
    departments = await _database.fetchDepartments();
    courses = await _database.fetchCourses();
    users = await _database.fetchUsers();
    attendance = await _database.fetchAttendance();
  }

  Future<String?> _markAttendance({
    required int studentId,
    required int courseId,
    required String method,
  }) async {
    final today = DateTime.now();
    final duplicate = await _database.isAttendanceRecorded(
      studentId: studentId,
      courseId: courseId,
      date: today,
    );
    if (duplicate) {
      return 'Attendance already recorded for today.';
    }
    await _database.insertAttendance(
      studentId: studentId,
      courseId: courseId,
      recordedAt: today,
      method: method,
    );
    await _reloadData();
    notifyListeners();
    return null;
  }

  String? _validateCommonRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return 'All fields are required.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _faceUserKey(UserAccount user) {
    return '${user.role.name}_${user.id}_${user.email.toLowerCase()}';
  }
}
