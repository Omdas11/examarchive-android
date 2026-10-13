import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PapersProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Paper> _papers = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  bool _hasMore = true;

  // Filters
  String _search = '';
  String? _department;
  int? _year;
  String? _semester;

  static const _pageSize = 40;

  List<Paper> get papers => _papers;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get search => _search;
  String? get department => _department;
  int? get year => _year;
  String? get semester => _semester;

  Future<void> refresh() async {
    _papers = [];
    _hasMore = true;
    _error = null;
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _loading = true;
    } else {
      _loadingMore = true;
    }
    notifyListeners();
    try {
      final items = await _api.fetchPapers(
        limit: _pageSize,
        offset: reset ? 0 : _papers.length,
        department: _department,
        year: _year,
        semester: _semester,
        search: _search.isEmpty ? null : _search,
      );
      if (reset) {
        _papers = items;
      } else {
        _papers = [..._papers, ...items];
      }
      _hasMore = items.length >= _pageSize;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  void setSearch(String v) {
    _search = v;
    refresh();
  }

  void setDepartment(String? v) {
    _department = v;
    refresh();
  }

  void setYear(int? v) {
    _year = v;
    refresh();
  }

  void setSemester(String? v) {
    _semester = v;
    refresh();
  }

  void clearFilters() {
    _search = '';
    _department = null;
    _year = null;
    _semester = null;
    refresh();
  }
}
