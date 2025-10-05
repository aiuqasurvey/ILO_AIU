import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'constants/config.dart';

class ApiService {


  // ----- GET ENDPOINTS -----

  Future<List<Map<String, dynamic>>> getFaculties() async {
    final res = await http.get(Uri.parse('$baseUrl/faculties'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch faculties: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getTracks(String facultyId) async {
    final res = await http.get(Uri.parse('$baseUrl/tracks/$facultyId'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch tracks');
  }

  Future<List<Map<String, dynamic>>> getCurriculums(String trackId) async {
    final res = await http.get(Uri.parse('$baseUrl/curriculums/$trackId'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch curriculums');
  }


  

Future<List<Map<String, dynamic>>> getBloomLevels() async {
  final uri = Uri.parse('$baseUrl/bloom-levels');
  final res = await http.get(uri);
  debugPrint('GET $uri => status: ${res.statusCode}');
  debugPrint('GET $uri => body: ${res.body}');
  if (res.statusCode == 200) {
    final decoded = json.decode(res.body);
    debugPrint('parsed bloom-levels: $decoded');
    return List<Map<String, dynamic>>.from(decoded);
  }
  throw Exception('Failed to fetch Bloom levels: ${res.statusCode} ${res.body}');
}


  Future<List<Map<String, dynamic>>> getVerbsForBloomLevel(int levelId) async {
    final res = await http.get(Uri.parse('$baseUrl/verbs/$levelId'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch verbs for level $levelId');
  }

  Future<List<Map<String, dynamic>>> getAllVerbs() async {
    final res = await http.get(Uri.parse('$baseUrl/verbs'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch all verbs');
  }

  // submissions
 /// Fetch all submissions with outcomes
  Future<List<Map<String, dynamic>>> getSubmissions({int? professorId}) async {
  final uri = Uri.parse('$baseUrl/submissions').replace(
    queryParameters: professorId != null ? {'professorId': '$professorId'} : null,
  );

  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('Failed to fetch submissions: ${res.body}');
  final List<dynamic> data = json.decode(res.body);
  return data.cast<Map<String, dynamic>>();
}


  // Delete submission
  Future<void> deleteSubmission(int submissionId) async {
    final res = await http.delete(Uri.parse('$baseUrl/submissions/$submissionId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete submission: ${res.body}');
    }
  }

  /// Create new submission with outcomes
  Future<int> submitILO(Map<String, dynamic> submission) async {
    final res = await http.post(
      Uri.parse('$baseUrl/submissions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(submission),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = json.decode(res.body);
      return body['id']; // backend returns { id: submissionId }
    }
    throw Exception('Submission failed: ${res.body}');
  }

  /// Update submission and replace outcomes
Future<void> updateILO(int submissionId, Map<String, dynamic> updatedData) async {
  if (updatedData['curriculum_id'] is String) {
    updatedData['curriculum_id'] = int.parse(updatedData['curriculum_id']);
  }
  final res = await http.put(
    Uri.parse('$baseUrl/submissions/$submissionId'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(updatedData),
  );
  if (res.statusCode != 200) {
    throw Exception('Failed to update submission: ${res.body}');
  }
}



  
  Future<List<Map<String, dynamic>>> getCurriculumsForProfessor(int professorId) async {
  final res = await http.get(Uri.parse('$baseUrl/curriculums/professor/$professorId'));
  if (res.statusCode == 200) {
    final decoded = json.decode(res.body);
    debugPrint('Curriculums fetched: $decoded');
    return List<Map<String, dynamic>>.from(decoded);
  }
  throw Exception('Failed to fetch curriculums for professor: ${res.statusCode}');
}


  Future<List<Map<String, dynamic>>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch users');
  }

  // ----- AUTH -----

  Future<Map<String, dynamic>> signup({
  required String username,
  required String password,
  required String professorName,
  required String email,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/signup'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'username': username,
      'password': password,
      'professorName': professorName,
      'email': email,
    }),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('Signup failed: ${res.body}');
  }

  return Map<String, dynamic>.from(json.decode(res.body));
}


 Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email, 'password': password}),
  );

  print('Status code: ${res.statusCode}');
  print('Response body: ${res.body}');

  if (res.statusCode == 200) {
    try {
      final data = Map<String, dynamic>.from(json.decode(res.body));
      return {
        'userId': data['userId'],
        'name': data['name'],
        'role': data['role'],
      };
    } catch (e) {
      throw Exception('Invalid JSON received from server');
    }
  } else {
    // Try decoding error from JSON, fallback to generic message
    try {
      final errorData = json.decode(res.body);
      throw Exception(errorData['error'] ?? 'Login failed');
    } catch (_) {
      throw Exception('Login failed: ${res.statusCode}');
    }
  }
}

  // ----- BLOOM LEVELS & VERBS -----

  Future<void> addBloomLevel({
    required String levelEn,
    required String levelAr,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add-bloom'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'level_en': levelEn, 'level_ar': levelAr}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Add bloom failed: ${res.body}');
    }
  }

  Future<void> addVerb({
    required int bloomLevelId,
    required String verbEn,
    required String verbAr,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add-verb'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'bloom_level_id': bloomLevelId,
        'verb_en': verbEn,
        'verb_ar': verbAr,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Add verb failed: ${res.body}');
    }
  }

Future<void> addCurriculum({
  required int trackId,
  required String name,
  required String curriculumCode,        
  String currPeriod = 'semester', 
  required int totalHours,
  required int lectureHours,
  required int labHours,
  String? prerequisites, // optional
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/add-curriculum'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'track_id': trackId,
      'name': name,
      'curriculum_code': curriculumCode, 
      'curr_period': currPeriod,
      'total_hours': totalHours,
      'lecture_hours': lectureHours,
      'lab_hours': labHours,
      'prerequisites': prerequisites ?? 'none',
    }),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('إضافة المقرر فشلت: ${res.body}');
  }
}

Future<void> updateCurriculum(
  int id, {
  required String name,
  required String curriculumCode,
  required String currPeriod,
  required int trackId,
  String? prerequisites,
}) async {
  final res = await http.put(
    Uri.parse('$baseUrl/curriculums/$id'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'name': name,
      'curriculum_code': curriculumCode,
      'curr_period': currPeriod,
      'track_id': trackId,
      'prerequisites': prerequisites,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('تحديث المقرر فشل: ${res.body}');
  }
}


  Future<void> deleteCurriculum(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/curriculums/$id'));
    if (res.statusCode != 200) throw Exception('Delete curriculum failed: ${res.body}');
  }

  Future<void> assignCurriculumToProfessor({
    required int professorId,
    required int curriculumId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/curriculums/assign'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'professorId': professorId, 'curriculumId': curriculumId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to assign curriculum: ${res.body}');
    }
  }

  Future<void> setUserAdmin(int userId, bool makeAdmin) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId/admin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_admin': makeAdmin}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update user role: ${res.body}');
  }
}
