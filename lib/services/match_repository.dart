// lib/services/match_repository.dart
//
// The single source of truth for matches. It:
//   1. holds the matches in memory,
//   2. saves/loads them to the phone as JSON (via shared_preferences),
//   3. notifies the UI when the list changes (it's a ChangeNotifier).
//
// The UI never touches storage directly — it only talks to this class. When we
// swap local storage for Firebase in milestone 4, ONLY this file changes.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class MatchRepository extends ChangeNotifier {
  static const _storageKey = 'matches_v1';
  final List<Match> _matches = [];

  /// Matches, newest first. Returns a read-only copy so callers can't mutate
  /// our internal list behind our back.
  List<Match> get matches {
    final sorted = List<Match>.from(_matches)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  // --- Derived stats (computed, never stored) ---
  int get totalMatches => _matches.length;
  int get wins => _matches.where((m) => m.didWin == true).length;
  double get winRate => totalMatches == 0 ? 0 : wins / totalMatches;

  /// Load saved matches from disk. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _matches.clear();
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _matches.addAll(
        decoded.map((e) => Match.fromJson(e as Map<String, dynamic>)),
      );
    }
    notifyListeners();
  }

  Future<void> addMatch(Match match) async {
    _matches.add(match);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteMatch(String id) async {
    _matches.removeWhere((m) => m.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_matches.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
