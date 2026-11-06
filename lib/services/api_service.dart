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

  /// Upload a paper PDF to Storage and create its database document.
  /// The paper goes to the moderation queue (approved=false), like the website.
  Future<void> uploadPaper({
    required String filePath,
    required String fileName,
    required String courseCode,
    required String department,
    required int year,
    required String semester,
    String? examType,
    String? paperType,
    String? programme,
  }) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppConfig.papersBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );
      final user = await AppwriteService().account.get();
      await _db.createDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        documentId: ID.unique(),
        data: {
          'course_code': courseCode.toUpperCase().trim(),
          'paper_name': courseCode.toUpperCase().trim(),
          'department': department,
          'year': year,
          'semester': semester,
          'exam_type': examType,
          'paper_type': paperType,
          'programme': programme ?? 'FYUGP',
          'institute': 'Haflong Government College',
          'file_id': file.$id,
          'file_url': '/api/files/papers/${file.$id}',
          'approved': false,
          'status': 'pending',
          'uploaded_by': user.$id,
        },
      );
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// Papers uploaded by the current user (for the dashboard).
  Future<List<Paper>> fetchMyUploads() async {
    try {
      final user = await AppwriteService().account.get();
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        queries: [
          Query.equal('uploaded_by', user.$id),
          Query.orderDesc(r'$createdAt'),
          Query.limit(50),
        ],
      );
      return res.documents.map((d) => Paper.fromJson(d.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// The current user's profile document from the `users` collection
  /// (role, XP, streak, upload count — same fields as the website's /profile).
  /// The doc is readable by its owner (Permission.read(Role.user(id))).
  Future<UserProfile?> fetchMyProfile() async {
    try {
      final user = await AppwriteService().account.get();
      final doc = await _db.getDocument(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.usersCollection,
        documentId: user.$id,
      );
      return UserProfile.fromJson(doc.data);
    } on AppwriteException catch (_) {
      return null;
    }
  }

  /// Number of content verifications this user has submitted
  /// (the website's verify-to-earn ledger).
  Future<int> fetchVerificationCount() async {
    try {
      final user = await AppwriteService().account.get();
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.verificationsCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.limit(1),
        ],
      );
      return res.total;
    } on AppwriteException catch (_) {
      return 0;
    }
  }

  /// Admin stats (moderator+): pending/approved paper counts and
  /// pending syllabus count. Reads only — approval stays on the website.
  Future<({int pendingPapers, int approvedPapers, int pendingSyllabi})>
      fetchAdminStats() async {
    try {
      final pending = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        queries: [Query.equal('approved', false), Query.limit(1)],
      );
      final approved = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        queries: [Query.equal('approved', true), Query.limit(1)],
      );
      final pendingSyl = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.syllabusCollection,
        queries: [
          Query.notEqual('approval_status', 'approved'),
          Query.limit(1),
        ],
      );
      return (
        pendingPapers: pending.total,
        approvedPapers: approved.total,
        pendingSyllabi: pendingSyl.total,
      );
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// Papers awaiting moderation (newest first).
  Future<List<Paper>> fetchPendingPapers({int limit = 50}) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.papersCollection,
        queries: [
          Query.equal('approved', false),
          Query.orderDesc(r'$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => Paper.fromJson(d.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// Syllabus entries awaiting moderation (newest first).
  Future<List<SyllabusEntry>> fetchPendingSyllabi({int limit = 50}) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.syllabusCollection,
        queries: [
          Query.notEqual('approval_status', 'approved'),
          Query.orderDesc(r'$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => SyllabusEntry.fromJson(d.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// All syllabus units for one department, grouped by paper code.
  /// Uses the paper-code prefix (e.g. PHY covers PHYDSC/PHYDSM/PHYIDC…).
  /// The department PDFs lived in the deleted `syllabus-files` bucket, so
  /// this table content is what the Syllabus tab shows now instead.
  Future<Map<String, List<SyllabusUnit>>> fetchDepartmentSyllabus(
      String prefix) async {
    final grouped = <String, List<SyllabusUnit>>{};
    var offset = 0;
    const pageSize = 100;
    while (true) {
      final res = await _db.listDocuments(
        databaseId: AppConfig.appwriteDatabaseId,
        collectionId: AppConfig.syllabusTableCollection,
        queries: [
          Query.equal('status', 'published'),
          Query.startsWith('paper_code', prefix),
          Query.orderAsc('paper_code'),
          Query.limit(pageSize),
          Query.offset(offset),
        ],
      );
      for (final d in res.documents) {
        final unit = SyllabusUnit.fromJson(d.data);
        if (unit.paperCode.isEmpty) continue;
        (grouped[unit.paperCode] ??= []).add(unit);
      }
      offset += res.documents.length;
      if (res.documents.length < pageSize || offset >= res.total) break;
    }
    // Units within each paper in unit-number order.
    for (final units in grouped.values) {
      units.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    }
    return grouped;
  }

  String _friendly(AppwriteException e) {
    final code = e.code ?? 0;
    if (code == 401) return 'Please log in again (session expired).';
    return e.message ?? 'Request failed ($code)';
  }
}
