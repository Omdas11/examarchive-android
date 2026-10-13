/// App-wide configuration: Appwrite backend only.
///
/// The app talks directly to the shared Appwrite project (Singapore) —
/// the same backend the website uses. No custom domain required.
class AppConfig {
  static const appVersion = '0.4.0-beta';

  static const appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const appwriteProjectId = '69a3e59300172d6a19cf';
  static const appwriteDatabaseId = 'examarchive';

  // Collections
  static const papersCollection = 'papers';
  static const syllabusCollection = 'syllabus';
  static const syllabusTableCollection = 'Syllabus_Table';

  // Storage buckets
  static const papersBucket = 'papers';
  static const syllabusBucket = 'syllabus-files';
}
