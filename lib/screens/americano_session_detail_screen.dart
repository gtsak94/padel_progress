// lib/screens/americano_session_detail_screen.dart
//
// View a saved session: final standings + each round's score, with delete.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/americano.dart';
import '../services/americano_repository.dart';
import '../theme.dart';
import 'americano_session_screen.dart'; // for AmericanoStandingsCard

class AmericanoSessionDetailScreen extends StatelessWidget {
  const AmericanoSessionDetailScreen({super.key, required this.session});
  final AmericanoSession session;

  @override
  Widget build(BuildContext context) {
    final standings = session.standings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            DateFormat('EEEE d MMMM y').format(session.date),
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text('Standings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AmericanoStandingsCard(standings: standings),
          const SizedBox(height: 24),
          Text('Rounds', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (int r = 0; r < session.rounds.length; r++) ...[
            _RoundSummary(session: session, round: r),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this session?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.loss),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AmericanoRepository>().deleteSession(session.id);
      Navigator.of(context).pop();
    }
  }
}

class _RoundSummary extends StatelessWidget {
  const _RoundSummary({required this.session, required this.round});
  final AmericanoSession session;
  final int round;

  @override
  Widget build(BuildContext context) {
    final pairing = AmericanoSession.pairings[round];
    final teamA = pairing[0];
    final teamB = pairing[1];
    final players = session.players;
    final score = session.rounds[round];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${players[teamA[0]]} & ${players[teamA[1]]}  vs  '
              '${players[teamB[0]]} & ${players[teamB[1]]}',
              style: const TextStyle(color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${score.gamesA}–${score.gamesB}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
