import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history_entry.dart';

/// Manages search history, persisting the last 20 searches to SharedPreferences.
class SearchHistoryProvider extends ChangeNotifier {
  static const _storageKey = 'search_history';
  static const _maxEntries = 20;

  List<SearchHistoryEntry> _entries = [];
  List<SearchHistoryEntry> get entries => List.unmodifiable(_entries);

  SearchHistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
        _entries = decoded
            .map((e) =>
                SearchHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (_) {
        _entries = [];
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Add a new search entry. Keeps only the most recent [_maxEntries].
  Future<void> addEntry(SearchHistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _saveHistory();
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    _entries = [];
    notifyListeners();
    await _saveHistory();
  }
}
