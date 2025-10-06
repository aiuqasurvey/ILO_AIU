import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:http/http.dart' as http;

final String baseUrl = kReleaseMode
    ? 'https://ilo-aiu.onrender.com/api'
    : 'http://localhost:5000/api';

dynamic safeJsonDecode(String body) {
  if (body.isEmpty) throw Exception('Empty response from server');
  if (body.startsWith('<!DOCTYPE html>')) {
    throw Exception('HTML response instead of JSON — likely a bad API URL or server misroute.');
  }
  try {
    return json.decode(body);
  } catch (e) {
    throw Exception('Invalid JSON response: $body');
  }
}


class ApiService {
  // ------------------ GET ------------------

  Future<List<Map<String, dynamic>>> getFaculties() async {
    return getList('faculties');
  }

  Future<List<Map<String, dynamic>>> getTracks(String facultyId) async {
    return getList('tracks/$facultyId');
  }

  Future<List<Map<String, dynamic>>> getCurriculums(String trackId) async {
    return getList('curriculums/$trackId');
  }

  Future<List<Map<String, dynamic>>> getCurriculumsForProfessor(int professorId) async {
    return getList('curriculums/professor/$professorId');
  }

  Future<List<Map<String, dynamic>>> getBloomLevels() async {
    return getList('bloom-levels');
  }

  Future<List<Map<String, dynamic>>> getAllVerbs() async {
    return getList('verbs');
  }

  Future<List<Map<String, dynamic>>> getVerbsForBloomLevel(int levelId) async {
    return getList('verbs/$levelId');
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return getList('users');
  }

  Future<List<Map<String, dynamic>>> getSubmissions({int? professorId}) async {
    final query = professorId != null ? '?professorId=$professorId' : '';
    return getList('submissions$query');
  }

  // ------------------ POST ------------------

  Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String professorName,
    required String email,
  }) async {
    return postMap('signup', {
      'username': username,
      'password': password,
      'professorName': professorName,
      'email': email,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return postMap('login', {'email': email, 'password': password});
  }

  Future<int> submitILO(Map<String, dynamic> submission) async {
    final res = await postMap('submissions', submission);
    if (res.containsKey('id')) return res['id'];
    throw Exception('Submission response missing ID: $res');
  }

  Future<void> assignCurriculumToProfessor({
    required int professorId,
    required int curriculumId,
  }) async {
    await post('curriculums/assign', {'professorId': professorId, 'curriculumId': curriculumId});
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
    await post('add-curriculum', {
      'track_id': trackId,
      'name': name,
      'curriculum_code': curriculumCode,
      'curr_period': currPeriod,
      'total_hours': totalHours,
      'lecture_hours': lectureHours,
      'lab_hours': labHours,
      'prerequisites': prerequisites ?? 'none',
    });
  }

  Future<void> addBloomLevel({
    required String levelEn,
    required String levelAr,
  }) async {
    await post('add-bloom', {'level_en': levelEn, 'level_ar': levelAr});
  }

  Future<void> addVerb({
    required int bloomLevelId,
    required String verbEn,
    required String verbAr,
  }) async {
    await post('add-verb', {
      'bloom_level_id': bloomLevelId,
      'verb_en': verbEn,
      'verb_ar': verbAr,
    });
  }

  // ------------------ PUT ------------------

  Future<void> updateILO(int submissionId, Map<String, dynamic> updatedData) async {
    await put('submissions/$submissionId', updatedData);
  }

  Future<void> updateCurriculum(
    int id, {
    required String name,
    required String curriculumCode,
    required String currPeriod,
    required int trackId,
    String? prerequisites,
  }) async {
    await put('curriculums/$id', {
      'name': name,
      'curriculum_code': curriculumCode,
      'curr_period': currPeriod,
      'track_id': trackId,
      'prerequisites': prerequisites,
    });
  }

  Future<void> setUserAdmin(int userId, bool makeAdmin) async {
    await put('users/$userId/admin', {'is_admin': makeAdmin});
  }

  // ------------------ DELETE ------------------

  Future<void> deleteSubmission(int submissionId) async {
    await delete('submissions/$submissionId');
  }

  Future<void> deleteCurriculum(int curriculumId) async {
    await delete('curriculums/$curriculumId');
  }

  // ------------------ INTERNAL HELPERS ------------------

  Future<List<Map<String, dynamic>>> getList(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('GET $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200) {
      final data = safeJsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      throw Exception('Expected List but got: $data');
    }
    throw Exception('GET $endpoint failed: ${res.body}');
  }

  Future<Map<String, dynamic>> postMap(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = safeJsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Expected Map but got: $data');
    }
    throw Exception('POST $endpoint failed: ${res.body}');
  }

  Future<void> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    debugPrint('POST $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST $endpoint failed: ${res.body}');
    }
  }

  Future<void> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.put(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    debugPrint('PUT $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('PUT $endpoint failed: ${res.body}');
  }

  Future<void> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.delete(uri, headers: {'Content-Type': 'application/json'});
    debugPrint('DELETE $uri => ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('DELETE $endpoint failed: ${res.body}');
  }
}
