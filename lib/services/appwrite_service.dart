import 'package:appwrite/appwrite.dart';
import '../config.dart';

/// Appwrite client singleton: everything runs directly against the Appwrite
/// backend (no custom domain needed).
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  bool _ready = false;

  void init() {
    if (_ready) return;
    client = Client()
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId)
        .setSelfSigned(status: false);
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    _ready = true;
  }
}
