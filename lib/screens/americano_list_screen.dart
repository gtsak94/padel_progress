// lib/screens/americano_list_screen.dart
//
// The "Americano" tab body: past sessions (newest first), or an empty state.
// The surrounding Scaffold/AppBar/FAB live in MainScaffold. Tapping a session
// opens its detail screen; the FAB (in MainScaffold) opens the setup screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/americano.dart';
import '../services/americano_repository.dart';
import '../theme.dart';
import 'americano_session_detail_screen.dart';

class AmericanoBody extends StatelessWidget {
  const AmericanoBody({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<AmericanoRepository>().sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No sessions yet.\nTap “New session” to start.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final s in sessions) ...[
          _SessionTile(session: s),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final AmericanoSession session;

  @override
  Widget build(BuildContext context) {
    final standings = session.standings;
    final winner = standings.isNotEmpty ? standings.first : null;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AmericanoSessionDetailScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.courtMid),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner != null ? 'Winner: ${winner.name}' : 'Session',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE d MMM').format(session.date),
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
