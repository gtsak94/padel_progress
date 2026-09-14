// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/match_repository.dart';
import '../theme.dart';
import 'scoreboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() rebuilds this screen whenever the repository calls
    // notifyListeners() — e.g. after a match is added.
    final repo = context.watch<MatchRepository>();
    final matches = repo.matches;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Padel Progress',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log a match'),
      ),
      body: matches.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _StatsHeader(repo: repo),
                const SizedBox(height: 24),
                Text(
                  'Recent matches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final m in matches) ...[
                  _MatchTile(match: m),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.repo});
  final MatchRepository repo;

  @override
  Widget build(BuildContext context) {
    final rate = (repo.winRate * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Matches', value: '${repo.totalMatches}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Win rate', value: '$rate%'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Wins', value: '${repo.wins}'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.court,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFontsSafe.heading(
              context,
            ).copyWith(color: Colors.white, fontSize: 30),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB9D6CF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Row(
        children: [
          _ResultBadge(didWin: match.didWin),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreLine(match),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE d MMM').format(match.date),
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.didWin});
  final bool? didWin;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (didWin) {
      true => ('W', AppColors.win),
      false => ('L', AppColors.loss),
      null => ('–', AppColors.inkSoft),
    };
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // An empty screen is an invitation to act, not a dead end.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_tennis,
              size: 56,
              color: AppColors.courtMid,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap “Log a match” to record your first one. '
              'Your stats and focus areas build from here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// "6–4 3–6 7–5" from a match's sets.
String scoreLine(Match match) {
  if (match.sets.isEmpty) return 'No score';
  return match.sets.map((s) => '${s.yourGames}–${s.theirGames}').join('  ');
}

/// Tiny helper so we can reuse the Archivo heading style with a custom size.
class GoogleFontsSafe {
  static TextStyle heading(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
}
