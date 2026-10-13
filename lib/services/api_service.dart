import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/models.dart';

/// HTTP client for the website's public JSON APIs (which proxy Appwrite).
class ApiService {
  final http.Client _client;
  ApiService([http.Client? client]) : _client = client ?? http.Client();

  static const _headers = {'User-Agent': 'ExamArchive-App/1.0'};

  Future<List<Paper>> fetchPapers({
    int limit = 60,
    int offset = 0,
    String? department,
    int? year,
    String? semester,
    String? examType,
    String? search,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (department != null && department.isNotEmpty) params['department'] = department;
    if (year != null) params['year'] = '$year';
    if (semester != null && semester.isNotEmpty) params['semester'] = semester;
    if (examType != null && examType.isNotEmpty) params['exam_type'] = examType;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse(AppConfig.papersApi).replace(queryParameters: params);
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load papers (${res.statusCode})');
    }
    final data = json.decode(res.body);
    final list = data is List ? data : (data['items'] as List? ?? []);
    return list.map((e) => Paper.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SyllabusEntry>> fetchSyllabusLibrary() async {
    final res = await _client.get(Uri.parse(AppConfig.syllabusApi), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load syllabus library (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final list = (data['items'] as List?) ?? [];
    return list.map((e) => SyllabusEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SyllabusUnit>> fetchSyllabusTable(Paper paper) async {
    final url = AppConfig.syllabusTableApi(
      paperCode: paper.courseCode,
      university: 'Assam University',
      course: 'FYUG',
      stream: paper.stream ?? '',
      type: paper.paperType ?? '',
    );
    final res = await _client.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final paperData = data['paper'] as Map<String, dynamic>?;
    final units = (paperData?['units'] as List?) ?? [];
    return units.map((e) => SyllabusUnit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Download bytes for a paper PDF via the JWT-gated app proxy.
  Future<List<int>> downloadPaperPdf({required String fileId, required String jwt}) async {
    final url = AppConfig.appDownloadUrl(fileId: fileId, jwt: jwt);
    final res = await _client.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Download failed (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  void dispose() => _client.close();
}
