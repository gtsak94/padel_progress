// lib/services/americano_repository.dart
//
// Stores Americano sessions locally. Same pattern as MatchRepository and
// ContactRepository: hold a list in memory, save/load as JSON, and
// notifyListeners() on every change so the UI reacts.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/americano.dart';

class AmericanoRepository extends ChangeNotifier {
  static const _storageKey = 'americano_sessions_v1';
  final List<AmericanoSession> _sessions = [];

  /// Sessions, newest first (read-only copy).
  List<AmericanoSession> get sessions {
    final sorted = List<AmericanoSession>.from(_sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  int get totalSessions => _sessions.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _sessions.clear();
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _sessions.addAll(
        decoded.map(
          (e) => AmericanoSession.fromJson(e as Map<String, dynamic>),
        ),
      );
    }
    notifyListeners();
  }

  Future<void> addSession(AmericanoSession session) async {
    _sessions.add(session);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
