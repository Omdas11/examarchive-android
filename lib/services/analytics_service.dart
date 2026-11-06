import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Analytics mirroring the website's own trackers — same property, same
/// counters, so web and app traffic land in one place.
///
/// Website trackers (examarchive-v3):
/// - GA4 (GoogleAnalytics.tsx): measurement ID G-FY13YB9STR, consent-gated.
///   The app sends page views to the same property via the g/collect
///   endpoint gtag.js itself uses (no API secret needed for that endpoint).
/// - Visitor counter (VisitorTracker + /api/visitor): the shared
///   `site_metrics` count. The app increments it once per install and
///   reads it for display — same counter as the website.
/// - Visit log (VisitLogger + /api/log-visit): one row per screen view.
/// - Simple Analytics: configured in code but NOT live on the site
///   (no trace in the production bundle), so there is nothing to mirror.
///
/// Everything here is fire-and-forget and never throws: analytics must
/// never break the app. Nothing runs until the user accepts analytics
/// (same consent gate as the website's cookie banner).
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const _gaMeasurementId = 'G-FY13YB9STR';
  static const _siteBase = 'https://examarchive.dev';

  static const _consentKey = 'analytics_consent';
  static const _clientIdKey = 'analytics_client_id';
  static const _visitRecordedKey = 'analytics_visit_recorded';
  static const _visitorCountKey = 'analytics_visitor_count';

  bool? _consented;
  String? _clientId;

  /// Has the user been asked (and answered) the analytics question?
  Future<bool> get hasConsentDecision async {
    if (_consented != null) return true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_consentKey)) {
      _consented = prefs.getBool(_consentKey) ?? false;
      return true;
    }
    return false;
  }

  bool get consented => _consented ?? false;

  Future<void> setConsented(bool value) async {
    _consented = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, value);
    if (value) {
      // Consent given: count this install as a visitor, then start logging.
      await recordVisit();
    }
  }

  Future<void> _ensureClientId() async {
    if (_clientId != null) return;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_clientIdKey);
    if (id == null || id.isEmpty) {
      id = _newUuid();
      await prefs.setString(_clientIdKey, id);
    }
    _clientId = id;
  }

  String _newUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now % 100000).toString().padLeft(5, '0');
    return '$now-$rand';
  }

  /// Count this install as one visitor (once ever). Mirrors the website's
  /// cookie dedup with a local flag, because the http client keeps no
  /// cookies — without the flag every launch would count again.
  Future<int?> recordVisit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_visitRecordedKey) == true) {
        return prefs.getInt(_visitorCountKey);
      }
      final res = await http
          .post(Uri.parse('$_siteBase/api/visitor'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final count = (data['visitor_count'] as num?)?.toInt();
        await prefs.setBool(_visitRecordedKey, true);
        if (count != null) await prefs.setInt(_visitorCountKey, count);
        return count;
      }
    } catch (_) {
      // Analytics must never break the app.
    }
    return null;
  }

  /// Current visitor count (shared with the website), without incrementing.
  Future<int?> fetchVisitorCount() async {
    try {
      final res = await http
          .get(Uri.parse('$_siteBase/api/visitor'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final count = (data['visitor_count'] as num?)?.toInt();
        if (count != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_visitorCountKey, count);
        }
        return count;
      }
    } catch (_) {}
    return null;
  }

  /// Log one screen view to GA4 and to the site's own visit log.
  /// No-op until the user accepts analytics.
  Future<void> trackScreen(String screenName, String path) async {
    if (!consented) return;
    await _ensureClientId();
    final cid = _clientId!;
    // GA4 page_view via the g/collect endpoint (same one gtag.js uses).
    try {
      final uri = Uri.parse('https://www.google-analytics.com/g/collect')
          .replace(queryParameters: {
        'v': '2',
        'tid': _gaMeasurementId,
        'cid': cid,
        'en': 'page_view',
        'dl': '$_siteBase/app/$path',
        'dt': screenName,
      });
      await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {}
    // Site visit log (same beacon the website's VisitLogger sends).
    try {
      await http
          .post(
            Uri.parse('$_siteBase/api/log-visit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'path': '/app/$path'}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// One-time consent dialog, mirroring the website's cookie banner.
  /// Returns true when the user accepted.
  static Future<bool> showConsentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Anonymous usage stats'),
        content: const Text(
          'Help improve ExamArchive by sharing anonymous usage stats '
          '(screens visited, no personal data). The website asks the same '
          'in its cookie banner. You can change this later in Profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
