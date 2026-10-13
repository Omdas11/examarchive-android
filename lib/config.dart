/// App-wide configuration: backend endpoints and IDs.
class AppConfig {
  // Appwrite backend (Singapore) — same project the website uses.
  static const appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const appwriteProjectId = '69a3e59300172d6a19cf';
  static const appwriteDatabaseId = 'examarchive';

  // Website API base (public JSON APIs). Uses the free deployment URL so the
  // app keeps working even without the custom domain.
  static const apiBase = 'https://www.examarchive.dev';

  static String get papersApi => '$apiBase/api/papers';
  static String get syllabusApi => '$apiBase/api/app/syllabus';
  static String syllabusTableApi({
    required String paperCode,
    required String university,
    required String course,
    required String stream,
    required String type,
  }) {
    final q = Uri(queryParameters: {
      'paperCode': paperCode,
      'university': university,
      'course': course,
      'stream': stream,
      'type': type,
      'mode': 'json',
    }).query;
    return '$apiBase/api/syllabus/table?$q';
  }

  static String appDownloadUrl({required String fileId, required String jwt}) {
    final q = Uri(queryParameters: {'fileId': fileId, 'jwt': jwt}).query;
    return '$apiBase/api/app/download?$q';
  }
}
