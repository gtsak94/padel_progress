// lib/screens/stats_screen.dart
//
// Stats v1: shows the basic numbers the MatchRepository already computes.
// It only DISPLAYS data (nothing changes inside it while you look), so it's a
// StatelessWidget — and because the numbers can change, we `watch` the repo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/match_repository.dart';
import '../theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() -> this screen rebuilds if matches change (e.g. you add one).
    final repo = context.watch<MatchRepository>();
    final winRate = (repo.winRate * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      // If there are no matches yet, invite the user to act instead of showing
      // empty cards.
      body: repo.totalMatches == 0
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No matches yet.\nLog a match to see your stats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft, height: 1.4),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(label: 'Win rate', value: '$winRate%'),
                const SizedBox(height: 12),
                _StatCard(
                  label: 'Matches played',
                  value: '${repo.totalMatches}',
                ),
                const SizedBox(height: 12),
                _StatCard(label: 'Wins', value: '${repo.wins}'),
              ],
            ),
    );
  }
}

// A full-width card: label on the left, big number on the right.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.court,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB9D6CF), fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
