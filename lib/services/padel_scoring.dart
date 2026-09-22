// lib/services/padel_scoring.dart
//
// All padel scoring rules live here — pure Dart, no UI. The scoreboard asks
// this class "is this match valid?" and shows whatever message comes back.
// Keeping the rules in one place means they're easy to read, change, and test.
//
// Rules encoded (tournament / FIP):
//   • Match: best of 3 — first to 2 sets wins.
//   • Sets 1 & 2: first to 6 games, win by 2. Valid finals: 6-0..6-4, 7-5, 7-6.
//   • Deciding 3rd set: SUPER TIEBREAK — first to 10 points, win by 2.

import '../models/models.dart';

class PadelScoring {
  /// A standard set: first to 6, win by 2; 7-5 or 7-6 (tiebreak) also valid.
  static bool isValidStandardSet(int a, int b) {
    final hi = a > b ? a : b;
    final lo = a > b ? b : a;
    if (hi == 6 && lo <= 4) return true; // 6-0 .. 6-4
    if (hi == 7 && (lo == 5 || lo == 6)) return true; // 7-5, 7-6
    return false;
  }

  /// The deciding super tiebreak: first to 10, win by 2 (10-8, 11-9, 12-10 ...).
  static bool isValidSuperTiebreak(int a, int b) {
    final hi = a > b ? a : b;
    final lo = a > b ? b : a;
    if (hi < 10) return false;
    if (hi - lo < 2) return false;
    if (hi == 10) return lo <= 8; // 10-0 .. 10-8
    return hi - lo == 2; // 11-9, 12-10, ...
  }

  /// Returns null if the whole match is a legal best-of-3, otherwise a
  /// human-readable reason it isn't (shown to the user on save).
  static String? validateMatch(List<PadelSet> sets) {
    if (sets.length < 2) {
      return 'A match needs at least two sets (best of 3).';
    }
    if (sets.length > 3) {
      return 'Best of 3 — a match can\'t have more than 3 sets.';
    }

    // First two sets are always standard sets.
    int youSets = 0;
    int themSets = 0;
    for (int i = 0; i < 2; i++) {
      final s = sets[i];
      if (!isValidStandardSet(s.yourGames, s.theirGames)) {
        return 'Set ${i + 1} (${s.yourGames}–${s.theirGames}) isn\'t a valid set. '
            'A set is first to 6, win by 2 (or 7–5, or 7–6).';
      }
      if (s.wonByYou) {
        youSets++;
      } else {
        themSets++;
      }
    }

    if (sets.length == 2) {
      // Two sets only makes sense if someone won both (2–0).
      if (youSets == themSets) {
        return 'It\'s 1–1 after two sets — add the deciding super tiebreak.';
      }
      return null; // 2–0 or 0–2: complete
    }

    // Three sets: only legal if the first two were split 1–1.
    if (youSets != themSets) {
      return 'The match was already won 2–0 after two sets — '
          'there shouldn\'t be a third.';
    }

    final third = sets[2];
    if (!isValidSuperTiebreak(third.yourGames, third.theirGames)) {
      return 'The deciding set is a super tiebreak — first to 10, win by 2 '
          '(e.g. 10–8 or 11–9). ${third.yourGames}–${third.theirGames} isn\'t valid.';
    }
    return null;
  }
}
