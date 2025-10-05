import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;

const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://ilo-aiu-web.onrender.com',
);


class ApiService {
  // ----- GET ENDPOINTS -----

  Future<List<Map<String, dynamic>>> getFaculties() async {
    final uri = Uri.parse('$baseUrl/faculties');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch faculties: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getTracks(String facultyId) async {
    final uri = Uri.parse('$baseUrl/tracks/$facultyId');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch tracks: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getCurriculums(String trackId) async {
    final uri = Uri.parse('$baseUrl/curriculums/$trackId');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch curriculums: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getCurriculumsForProfessor(int professorId) async {
    final uri = Uri.parse('$baseUrl/curriculums/professor/$professorId');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch curriculums for professor: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getBloomLevels() async {
    final uri = Uri.parse('$baseUrl/bloom-levels');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch Bloom levels: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getAllVerbs() async {
    final uri = Uri.parse('$baseUrl/verbs');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch verbs: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getVerbsForBloomLevel(int levelId) async {
    final uri = Uri.parse('$baseUrl/verbs/$levelId');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch verbs for level $levelId: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final uri = Uri.parse('$baseUrl/users');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch users: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getSubmissions({int? professorId}) async {
    final uri = Uri.parse('$baseUrl/submissions').replace(
      queryParameters: professorId != null ? {'professorId': '$professorId'} : null,
    );
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch submissions: ${res.body}');
  }

  // ----- DELETE -----
  Future<void> deleteSubmission(int submissionId) async {
    final uri = Uri.parse('$baseUrl/submissions/$submissionId');
    final res = await http.delete(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('DELETE $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Failed to delete submission: ${res.body}');
  }

  Future<void> deleteCurriculum(int id) async {
    final uri = Uri.parse('$baseUrl/curriculums/$id');
    final res = await http.delete(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) throw Exception('Delete curriculum failed: ${res.body}');
  }

  // ----- POST/PUT -----
  Future<int> submitILO(Map<String, dynamic> submission) async {
    final uri = Uri.parse('$baseUrl/submissions');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(submission),
    );
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body)['id'];
    }
    throw Exception('Submission failed: ${res.body}');
  }

  Future<void> updateILO(int submissionId, Map<String, dynamic> updatedData) async {
    final uri = Uri.parse('$baseUrl/submissions/$submissionId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedData),
    );
    debugPrint('PUT $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Failed to update submission: ${res.body}');
  }

  Future<void> assignCurriculumToProfessor({required int professorId, required int curriculumId}) async {
    final uri = Uri.parse('$baseUrl/curriculums/assign');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'professorId': professorId, 'curriculumId': curriculumId}),
    );
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to assign curriculum: ${res.body}');
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
    String? prerequisites,
  }) async {
    final uri = Uri.parse('$baseUrl/add-curriculum');
    final res = await http.post(
      uri,
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
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Add curriculum failed: ${res.body}');
  }

  Future<void> updateCurriculum(
    int id, {
    required String name,
    required String curriculumCode,
    required String currPeriod,
    required int trackId,
    String? prerequisites,
  }) async {
    final uri = Uri.parse('$baseUrl/curriculums/$id');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'curriculum_code': curriculumCode,
        'curr_period': currPeriod,
        'track_id': trackId,
        'prerequisites': prerequisites,
      }),
    );
    debugPrint('PUT $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Update curriculum failed: ${res.body}');
  }

  Future<void> addBloomLevel({required String levelEn, required String levelAr}) async {
    final uri = Uri.parse('$baseUrl/add-bloom');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'level_en': levelEn, 'level_ar': levelAr}));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Add bloom level failed: ${res.body}');
  }

  Future<void> addVerb({required int bloomLevelId, required String verbEn, required String verbAr}) async {
    final uri = Uri.parse('$baseUrl/add-verb');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bloom_level_id': bloomLevelId, 'verb_en': verbEn, 'verb_ar': verbAr}));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Add verb failed: ${res.body}');
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String professorName,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/signup');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'professorName': professorName,
          'email': email,
        }));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(json.decode(res.body));
    }
    throw Exception('Signup failed: ${res.body}');
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/login');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body));
    }
    throw Exception('Login failed: ${res.body}');
  }

  Future<void> setUserAdmin(int userId, bool makeAdmin) async {
    final uri = Uri.parse('$baseUrl/users/$userId/admin');
    final res = await http.put(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_admin': makeAdmin}));
    debugPrint('PUT $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Failed to update user role: ${res.body}');
  }
}
