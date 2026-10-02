// lib/screens/stats_screen.dart
//
// The "Stats" tab body: the basic numbers from MatchRepository, or an empty
// state. The surrounding Scaffold/AppBar live in MainScaffold.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/match_repository.dart';
import '../theme.dart';

class StatsBody extends StatelessWidget {
  const StatsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MatchRepository>();
    final winRate = (repo.winRate * 100).round();

    if (repo.totalMatches == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No matches yet.\nLog a match to see your stats.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(label: 'Win rate', value: '$winRate%'),
        const SizedBox(height: 12),
        _StatCard(label: 'Matches played', value: '${repo.totalMatches}'),
        const SizedBox(height: 12),
        _StatCard(label: 'Wins', value: '${repo.wins}'),
      ],
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
