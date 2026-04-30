import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../core/models/entities.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  static const _databaseName = 'attendease.db';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<UserAccount?> findUserByCredentials({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.toLowerCase(), password],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _userFromMap(rows.first);
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<UserAccount>> fetchUsers() async {
    final db = await database;
    final rows = await db.query(
      'users',
      orderBy: 'role, first_name, last_name',
    );
    return rows.map(_userFromMap).toList();
  }

  Future<int> insertStudent({
    required String firstName,
    required String lastName,
    required String department,
    required String rollNumber,
    required String email,
    required String password,
  }) async {
    final db = await database;
    return db.insert('users', {
      'role': UserRole.student.name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email.toLowerCase(),
      'password': password,
      'department': department,
      'roll_number': rollNumber,
      'is_active': 0,
      'has_face_registered': 0,
    });
  }

  Future<int> insertTeacher({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final db = await database;
    return db.insert('users', {
      'role': UserRole.teacher.name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email.toLowerCase(),
      'password': password,
      'is_active': 0,
      'has_face_registered': 0,
    });
  }

  Future<void> updateUserStatus(int userId, bool isActive) async {
    final db = await database;
    await db.update(
      'users',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserFaceRegistered(int userId, bool registered) async {
    final db = await database;
    await db.update(
      'users',
      {'has_face_registered': registered ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Department>> fetchDepartments() async {
    final db = await database;
    final rows = await db.query('departments', orderBy: 'name');
    return rows.map(_departmentFromMap).toList();
  }

  Future<bool> departmentExists(String name) async {
    final db = await database;
    final rows = await db.query(
      'departments',
      columns: ['id'],
      where: 'lower(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> insertDepartment(String name) async {
    final db = await database;
    return db.insert('departments', {'name': name});
  }

  Future<List<Course>> fetchCourses() async {
    final db = await database;
    final rows = await db.query('courses', orderBy: 'name');
    return rows.map(_courseFromMap).toList();
  }

  Future<bool> courseExists(String name) async {
    final db = await database;
    final rows = await db.query(
      'courses',
      columns: ['id'],
      where: 'lower(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> insertCourse({required String name, required int credits}) async {
    final db = await database;
    return db.insert('courses', {
      'name': name,
      'credits': credits,
      'is_active': 1,
    });
  }

  Future<void> updateCourseStatus(int courseId, bool isActive) async {
    final db = await database;
    await db.update(
      'courses',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<List<AttendanceRecord>> fetchAttendance() async {
    final db = await database;
    final rows = await db.query('attendance', orderBy: 'recorded_at DESC');
    return rows.map(_attendanceFromMap).toList();
  }

  Future<bool> isAttendanceRecorded({
    required int studentId,
    required int courseId,
    required DateTime date,
  }) async {
    final db = await database;
    final day = _dateOnly(date);
    final rows = await db.query(
      'attendance',
      columns: ['id'],
      where: 'student_id = ? AND course_id = ? AND attendance_date = ?',
      whereArgs: [studentId, courseId, day],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> insertAttendance({
    required int studentId,
    required int courseId,
    required DateTime recordedAt,
    required String method,
  }) async {
    final db = await database;
    return db.insert('attendance', {
      'student_id': studentId,
      'course_id': courseId,
      'attendance_date': _dateOnly(recordedAt),
      'recorded_at': recordedAt.toIso8601String(),
      'method': method,
    });
  }

  Future<bool> hasAnyUsers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM users');
    return (result.first['count'] as int) > 0;
  }

  Future<void> seedIfEmpty() async {
    if (await hasAnyUsers()) {
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      final csId = await txn.insert('departments', {
        'name': 'Computer Science',
      });
      await txn.insert('departments', {'name': 'Business Studies'});
      await txn.insert('departments', {'name': 'Design'});

      final mobileId = await txn.insert('courses', {
        'name': 'Mobile Computing',
        'credits': 3,
        'is_active': 1,
      });
      await txn.insert('courses', {
        'name': 'Cloud Fundamentals',
        'credits': 4,
        'is_active': 1,
      });
      await txn.insert('courses', {
        'name': 'Human Computer Interaction',
        'credits': 2,
        'is_active': 0,
      });

      await txn.insert('users', {
        'role': UserRole.teacher.name,
        'first_name': 'Ava',
        'last_name': 'Sharma',
        'email': 'teacher@attendease.app',
        'password': 'teacher123',
        'is_active': 1,
        'has_face_registered': 0,
      });

      final studentId = await txn.insert('users', {
        'role': UserRole.student.name,
        'first_name': 'Milan',
        'last_name': 'Raut',
        'email': 'student@attendease.app',
        'password': 'student123',
        'department': 'Computer Science',
        'roll_number': 'CS-24-019',
        'is_active': 1,
        'has_face_registered': 0,
      });

      await txn.insert('users', {
        'role': UserRole.student.name,
        'first_name': 'Riya',
        'last_name': 'Thapa',
        'email': 'riya@attendease.app',
        'password': 'student123',
        'department': 'Design',
        'roll_number': 'DS-24-007',
        'is_active': 0,
        'has_face_registered': 0,
      });

      final recordedAt = DateTime.now().subtract(const Duration(days: 1));
      await txn.insert('attendance', {
        'student_id': studentId,
        'course_id': mobileId,
        'attendance_date': _dateOnly(recordedAt),
        'recorded_at': recordedAt.toIso8601String(),
        'method': 'Face verified',
      });

      if (csId <= 0) {
        throw StateError('Failed to seed departments');
      }
    });
  }

  Future<Database> _openDatabase() async {
    final databasePath = await _resolveDatabasePath();
    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            department TEXT,
            roll_number TEXT,
            is_active INTEGER NOT NULL DEFAULT 0,
            has_face_registered INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE departments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('''
          CREATE TABLE courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            credits INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            course_id INTEGER NOT NULL,
            attendance_date TEXT NOT NULL,
            recorded_at TEXT NOT NULL,
            method TEXT NOT NULL,
            UNIQUE(student_id, course_id, attendance_date)
          )
        ''');
      },
    );
  }

  Future<String> _resolveDatabasePath() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return _databaseName;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return path.join(await getDatabasesPath(), _databaseName);
    }

    // Initialize FFI for Desktop (Linux, Windows, macOS)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, _databaseName);
  }

  UserAccount _userFromMap(Map<String, Object?> map) {
    return UserAccount(
      id: map['id'] as int,
      role: UserRole.values.byName(map['role'] as String),
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      department: map['department'] as String?,
      rollNumber: map['roll_number'] as String?,
      isActive: (map['is_active'] as int) == 1,
      hasFaceRegistered: (map['has_face_registered'] as int) == 1,
    );
  }

  Department _departmentFromMap(Map<String, Object?> map) {
    return Department(id: map['id'] as int, name: map['name'] as String);
  }

  Course _courseFromMap(Map<String, Object?> map) {
    return Course(
      id: map['id'] as int,
      name: map['name'] as String,
      credits: map['credits'] as int,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  AttendanceRecord _attendanceFromMap(Map<String, Object?> map) {
    return AttendanceRecord(
      id: map['id'] as int,
      studentId: map['student_id'] as int,
      courseId: map['course_id'] as int,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      method: map['method'] as String,
    );
  }

  String _dateOnly(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
