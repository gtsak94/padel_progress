// lib/models/americano.dart
//
// Data model for a casual "Americano" session.
// 4 players, 3 rounds. Every pair of players teams up exactly once.
// Each round is one set; we store each team's games. A player's score is the
// total games their team won across the 3 rounds. Rank players by total games.

/// One round's set score: games won by team A and team B.
class RoundScore {
  final int gamesA;
  final int gamesB;
  const RoundScore({this.gamesA = 0, this.gamesB = 0});

  Map<String, dynamic> toJson() => {'gamesA': gamesA, 'gamesB': gamesB};

  factory RoundScore.fromJson(Map<String, dynamic> json) => RoundScore(
    gamesA: json['gamesA'] as int? ?? 0,
    gamesB: json['gamesB'] as int? ?? 0,
  );
}

class AmericanoSession {
  final String id;
  final DateTime date;
  final List<String> players; // exactly 4 names, at index 0..3
  final List<RoundScore> rounds; // exactly 3, at index 0..2

  const AmericanoSession({
    required this.id,
    required this.date,
    required this.players,
    required this.rounds,
  });

  // The fixed pairings for 4 players (by their index 0..3).
  // Each round has [teamA, teamB], and each team is a pair of player indexes.
  //   Round 0: (0 & 1)  vs  (2 & 3)
  //   Round 1: (0 & 2)  vs  (1 & 3)
  //   Round 2: (0 & 3)  vs  (1 & 2)
  // With these three rounds, every player has partnered everyone once.
  static const List<List<List<int>>> pairings = [
    [
      [0, 1],
      [2, 3],
    ],
    [
      [0, 2],
      [1, 3],
    ],
    [
      [0, 3],
      [1, 2],
    ],
  ];

  /// Total games each player collected, as playerIndex -> games.
  Map<int, int> get totalsByPlayer {
    final totals = {0: 0, 1: 0, 2: 0, 3: 0};
    for (int r = 0; r < rounds.length; r++) {
      final teamA = pairings[r][0]; // the two player indexes on team A
      final teamB = pairings[r][1];
      final score = rounds[r];
      for (final p in teamA) {
        totals[p] =
            totals[p]! + score.gamesA; // team A's games go to A's players
      }
      for (final p in teamB) {
        totals[p] = totals[p]! + score.gamesB;
      }
    }
    return totals;
  }

  /// Players ranked best-first. Each entry is a record: (name, games).
  List<({String name, int games})> get standings {
    final totals = totalsByPlayer;
    final list = [
      for (int i = 0; i < players.length; i++)
        (name: players[i], games: totals[i] ?? 0),
    ];
    list.sort((a, b) => b.games.compareTo(a.games)); // highest games first
    return list;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'players': players,
    'rounds': rounds.map((r) => r.toJson()).toList(),
  };

  factory AmericanoSession.fromJson(Map<String, dynamic> json) =>
      AmericanoSession(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        players: (json['players'] as List<dynamic>).cast<String>(),
        rounds: (json['rounds'] as List<dynamic>)
            .map((e) => RoundScore.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
