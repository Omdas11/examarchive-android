import 'package:appwrite/appwrite.dart';
import '../config.dart';
import '../models/models.dart';
import 'appwrite_service.dart';

/// Data layer: talks directly to the shared Appwrite backend.
/// Requires a logged-in user — collections and buckets grant read access
/// to authenticated users, matching the website's login-gated policy.
class ApiService {
  Databases get _db => AppwriteService().databases;
  Storage get _storage => AppwriteService().storage;

  Future<List<Paper>> fetchPapers({
    int limit = 60,
    int offset = 0,
    String? department,
    int? year,
    String? semester,
    String? examType,
    String? search,
  }) async {
    final queries = <String>[
      Query.equal('approved', true),
      Query.orderDesc(r'$createdAt'),
      Query.limit(limit),
      Query.offset(offset),
    ];
    if (department != null && department.isNotEmpty) {
      queries.add(Query.equal('department', department));
    }
    if (year != null) queries.add(Query.equal('year', year));
    if (semester != null && semester.isNotEmpty) {
      queries.add(Query.equal('semester', semester));
    }
    if (examType != null && examType.isNotEmpty) {
      queries.add(Query.equal('exam_type', examType));
    }
    if (search != null && search.isNotEmpty) {
      queries.add(Query.search('course_name', search));
    }
    try {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        queries: queries,
      );
      return res.documents.map((d) => Paper.fromJson(d.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  Future<List<SyllabusEntry>> fetchSyllabusLibrary() async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.syllabusCollection,
        queries: [
          Query.equal('approval_status', 'approved'),
          Query.orderAsc('subject'),
          Query.limit(100),
        ],
      );
      return res.documents.map((d) => SyllabusEntry.fromJson(d.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  Future<List<SyllabusUnit>> fetchSyllabusTable(Paper paper) async {
    final code = paper.courseCode.toUpperCase().trim();
    if (code.isEmpty) return [];
    final queries = <String>[
      Query.equal('status', 'published'),
      Query.equal('paper_code', code),
      Query.orderAsc(r'$id'),
      Query.limit(100),
    ];
    // Narrow further when the paper carries stream/type, like the website.
    if (paper.stream != null && paper.stream!.isNotEmpty) {
      queries.add(Query.equal('stream', paper.stream!));
    }
    if (paper.paperType != null && paper.paperType!.isNotEmpty) {
      queries.add(Query.equal('type', paper.paperType!));
    }
    try {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.syllabusTableCollection,
        queries: queries,
      );
      return res.documents.map((d) => SyllabusUnit.fromJson(d.data)).toList();
    } on AppwriteException catch (_) {
      return [];
    }
  }

  /// Download a paper PDF's bytes straight from Appwrite Storage.
  Future<List<int>> downloadPaperPdf(String fileId) async {
    try {
      final bytes = await _storage.getFileDownload(
        bucketId: AppConfig.papersBucket,
        fileId: fileId,
      );
      return bytes;
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// Download a syllabus PDF's bytes straight from Appwrite Storage.
  Future<List<int>> downloadSyllabusPdf(String fileId) async {
    try {
      final bytes = await _storage.getFileDownload(
        bucketId: AppConfig.syllabusBucket,
        fileId: fileId,
      );
      return bytes;
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  String _friendly(AppwriteException e) {
    final code = e.code ?? 0;
    if (code == 401) return 'Please log in again (session expired).';
    return e.message ?? 'Request failed ($code)';
  }
}
