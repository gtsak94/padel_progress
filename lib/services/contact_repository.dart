// lib/services/contact_repository.dart
//
// Stores the player's roster of partners & opponents (Contacts) locally.
// This is the SAME pattern as MatchRepository on purpose: hold a list in
// memory, save/load it as JSON, and notifyListeners() when it changes.
// Once you've seen one repository, you've seen them all.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class ContactRepository extends ChangeNotifier {
  static const _storageKey = 'contacts_v1';
  final List<Contact> _contacts = [];

  /// Contacts sorted alphabetically. Read-only copy so callers can't mutate
  /// our internal list.
  List<Contact> get contacts {
    final sorted = List<Contact>.from(_contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  /// Look one up by id (used to turn a match's partnerId into a name).
  /// Returns null if not found.
  Contact? byId(String? id) {
    if (id == null) return null;
    for (final c in _contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _contacts.clear();
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _contacts.addAll(
        decoded.map((e) => Contact.fromJson(e as Map<String, dynamic>)),
      );
    }
    notifyListeners();
  }

  /// Find an existing contact by name (case-insensitive), or create one.
  /// This is what stops "Nikos" and "nikos" becoming two different players —
  /// the key to reliable "best partner" stats later.
  Future<Contact> findOrCreate(String name) async {
    final trimmed = name.trim();
    for (final c in _contacts) {
      if (c.name.toLowerCase() == trimmed.toLowerCase()) return c;
    }
    final created = Contact(id: const Uuid().v4(), name: trimmed);
    _contacts.add(created);
    await _persist();
    notifyListeners();
    return created;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
