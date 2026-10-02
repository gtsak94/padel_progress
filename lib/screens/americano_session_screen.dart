// lib/screens/americano_session_screen.dart
//
// Step 2: score the 3 rounds and see the live standings, then Save.
// Each round is one set, so on Save we validate every round with the same
// padel set rules as the match scoreboard (6–4, 7–5, 7–6, …). Standings
// recompute on every tap by building a temporary session and reading
// .standings.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/americano.dart';
import '../services/americano_repository.dart';
import '../services/padel_scoring.dart';
import '../theme.dart';

class AmericanoSessionScreen extends StatefulWidget {
  const AmericanoSessionScreen({super.key, required this.players});
  final List<String> players;

  @override
  State<AmericanoSessionScreen> createState() => _AmericanoSessionScreenState();
}

class _AmericanoSessionScreenState extends State<AmericanoSessionScreen> {
  // Editable scores: for each of the 3 rounds, [gamesA, gamesB].
  final List<List<int>> _scores = List.generate(3, (_) => [0, 0]);

  void _bump(int round, int side, int delta) {
    setState(() {
      final next = _scores[round][side] + delta;
      if (next >= 0 && next <= 99) _scores[round][side] = next;
    });
  }

  // Build a session object from the current scores (for live standings + save).
  AmericanoSession _buildSession() {
    return AmericanoSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      players: widget.players,
      rounds: _scores
          .map((s) => RoundScore(gamesA: s[0], gamesB: s[1]))
          .toList(),
    );
  }

  void _save() {
    // Every round must be a valid set (first to 6, win by 2, or 7–5 / 7–6).
    // This also blocks saving with unfinished rounds (e.g. 0–0, 3–2).
    for (int r = 0; r < _scores.length; r++) {
      final a = _scores[r][0];
      final b = _scores[r][1];
      if (!PadelScoring.isValidStandardSet(a, b)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round ${r + 1} ($a–$b) isn\'t a valid set. '
              'A set is first to 6, win by 2 (or 7–5, or 7–6).',
            ),
            backgroundColor: AppColors.loss,
          ),
        );
        return; // stop — nothing is saved
      }
    }

    context.read<AmericanoRepository>().addSession(_buildSession());
    Navigator.of(context).pop(); // back to the list
  }

  @override
  Widget build(BuildContext context) {
    final standings = _buildSession().standings;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (int r = 0; r < 3; r++) ...[
            _RoundCard(
              round: r,
              players: widget.players,
              gamesA: _scores[r][0],
              gamesB: _scores[r][1],
              onBump: _bump,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text('Standings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AmericanoStandingsCard(standings: standings),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.court,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// One round: the two teams (from the fixed pairings) with score counters.
class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.players,
    required this.gamesA,
    required this.gamesB,
    required this.onBump,
  });

  final int round;
  final List<String> players;
  final int gamesA;
  final int gamesB;
  final void Function(int round, int side, int delta) onBump;

  @override
  Widget build(BuildContext context) {
    final pairing = AmericanoSession.pairings[round];
    final teamA = pairing[0];
    final teamB = pairing[1];
    final teamAName = '${players[teamA[0]]} & ${players[teamA[1]]}';
    final teamBName = '${players[teamB[0]]} & ${players[teamB[1]]}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Round ${round + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _TeamRow(
            name: teamAName,
            games: gamesA,
            onDelta: (d) => onBump(round, 0, d),
          ),
          const Divider(height: 18),
          _TeamRow(
            name: teamBName,
            games: gamesB,
            onDelta: (d) => onBump(round, 1, d),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.name,
    required this.games,
    required this.onDelta,
  });
  final String name;
  final int games;
  final void Function(int delta) onDelta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: AppColors.ink, fontSize: 15),
          ),
        ),
        _RoundBtn(icon: Icons.remove, onTap: () => onDelta(-1)),
        SizedBox(
          width: 34,
          child: Text(
            '$games',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        _RoundBtn(icon: Icons.add, onTap: () => onDelta(1)),
      ],
    );
  }
}

// Shared standings card (public so the detail screen can reuse it).
class AmericanoStandingsCard extends StatelessWidget {
  const AmericanoStandingsCard({super.key, required this.standings});
  final List<({String name, int games})> standings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.court,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < standings.length; i++) ...[
            Row(
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    color: Color(0xFFB9D6CF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    standings[i].name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Text(
                  '${standings[i].games}',
                  style: const TextStyle(
                    color: AppColors.ball,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (i < standings.length - 1)
              const Divider(height: 18, color: Color(0x33FFFFFF)),
          ],
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.court),
      ),
    );
  }
}
