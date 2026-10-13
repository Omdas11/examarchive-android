import 'package:appwrite/appwrite.dart';
import '../config.dart';

/// Appwrite client singleton: auth runs directly against the Appwrite
/// backend (no custom domain needed).
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late final Client client;
  late final Account account;
  bool _ready = false;

  void init() {
    if (_ready) return;
    client = Client()
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId)
        .setSelfSigned(status: false);
    account = Account(client);
    _ready = true;
  }

  /// Short-lived JWT for the website's app download proxy.
  Future<String> createDownloadJwt() async {
    final jwt = await account.createJWT();
    return jwt.jwt;
  }
}
