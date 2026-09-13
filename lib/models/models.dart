// lib/models/models.dart
//
// Data models for Padel Progress (v1).
//
// Note: this file is PURE DART — it imports nothing from Flutter. Models
// describe the *shape* of our data and how to turn it into/out of JSON so we
// can save it to the phone (milestone 2) and later to the cloud (milestone 4).
// Keeping them free of UI code makes them easy to test and reuse.

/// How a match was scored. v1 really only needs `sets`; `americano` is here so
/// we don't have to change the model later when we add that format.
enum MatchFormat { sets, americano }

/// The account owner's subscription state. Drives the paywall gating later.
enum SubscriptionStatus { free, premium }

/// A person you play with or against.
///
/// These are NOT app users — just names in your personal roster of padel
/// partners/opponents. Storing them as their own entity is what lets us build
/// "best partner" and head-to-head stats later.
class Contact {
  final String id;
  final String name;
  final String? level; // optional self-noted level, e.g. "3.5"

  const Contact({required this.id, required this.name, this.level});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        level: json['level'] as String?,
      );
}

/// One set within a match, from YOUR perspective.
/// `tiebreak` simply flags that the set went to a tiebreak; we can store the
/// actual tiebreak points later if we ever want that detail.
class PadelSet {
  final int yourGames;
  final int theirGames;
  final bool tiebreak;

  const PadelSet({
    required this.yourGames,
    required this.theirGames,
    this.tiebreak = false,
  });

  /// Did you win this set?
  bool get wonByYou => yourGames > theirGames;

  Map<String, dynamic> toJson() => {
        'yourGames': yourGames,
        'theirGames': theirGames,
        'tiebreak': tiebreak,
      };

  factory PadelSet.fromJson(Map<String, dynamic> json) => PadelSet(
        yourGames: json['yourGames'] as int,
        theirGames: json['theirGames'] as int,
        tiebreak: (json['tiebreak'] as bool?) ?? false,
      );
}

/// A single played match.
class Match {
  final String id;
  final DateTime date;
  final int? durationMinutes;
  final String? location;
  final MatchFormat format;

  // Your partner and the two opponents, referenced by Contact id.
  final String? partnerId;
  final String? opponent1Id;
  final String? opponent2Id;

  final List<PadelSet> sets;
  final String? notes;
  final List<String> tags;

  const Match({
    required this.id,
    required this.date,
    this.durationMinutes,
    this.location,
    this.format = MatchFormat.sets,
    this.partnerId,
    this.opponent1Id,
    this.opponent2Id,
    this.sets = const [],
    this.notes,
    this.tags = const [],
  });

  /// Sets you won.
  int get setsWon => sets.where((s) => s.wonByYou).length;

  /// Sets your opponents won.
  int get setsLost => sets.where((s) => !s.wonByYou).length;

  /// Did you win the match overall? Returns null for a tie / unfinished match.
  /// We COMPUTE this from the sets instead of storing it, so it can never
  /// disagree with the actual score.
  bool? get didWin {
    if (setsWon == setsLost) return null;
    return setsWon > setsLost;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'location': location,
        'format': format.name,
        'partnerId': partnerId,
        'opponent1Id': opponent1Id,
        'opponent2Id': opponent2Id,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
        'tags': tags,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        durationMinutes: json['durationMinutes'] as int?,
        location: json['location'] as String?,
        format: MatchFormat.values
            .byName((json['format'] as String?) ?? MatchFormat.sets.name),
        partnerId: json['partnerId'] as String?,
        opponent1Id: json['opponent1Id'] as String?,
        opponent2Id: json['opponent2Id'] as String?,
        sets: (json['sets'] as List<dynamic>? ?? const [])
            .map((e) => PadelSet.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

/// The account owner.
class Player {
  final String id;
  final String displayName;
  final String? selfRatedLevel;
  final DateTime createdAt;
  final SubscriptionStatus subscriptionStatus;

  const Player({
    required this.id,
    required this.displayName,
    this.selfRatedLevel,
    required this.createdAt,
    this.subscriptionStatus = SubscriptionStatus.free,
  });

  bool get isPremium => subscriptionStatus == SubscriptionStatus.premium;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'selfRatedLevel': selfRatedLevel,
        'createdAt': createdAt.toIso8601String(),
        'subscriptionStatus': subscriptionStatus.name,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        selfRatedLevel: json['selfRatedLevel'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        subscriptionStatus: SubscriptionStatus.values.byName(
            (json['subscriptionStatus'] as String?) ??
                SubscriptionStatus.free.name),
      );
}

/// A piece of AI-generated "what to work on next" feedback.
class Insight {
  final String id;
  final DateTime generatedAt;
  final String summaryText;
  final String? focusArea;
  final List<String> matchIdsCovered;

  const Insight({
    required this.id,
    required this.generatedAt,
    required this.summaryText,
    this.focusArea,
    this.matchIdsCovered = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'generatedAt': generatedAt.toIso8601String(),
        'summaryText': summaryText,
        'focusArea': focusArea,
        'matchIdsCovered': matchIdsCovered,
      };

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        summaryText: json['summaryText'] as String,
        focusArea: json['focusArea'] as String?,
        matchIdsCovered:
            (json['matchIdsCovered'] as List<dynamic>? ?? const [])
                .cast<String>(),
      );
}

/// A user-set goal, e.g. "win 60% of my matches this month".
class Goal {
  final String id;
  final String description;
  final double progress; // 0.0 .. 1.0
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.description,
    this.progress = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        description: json['description'] as String,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}