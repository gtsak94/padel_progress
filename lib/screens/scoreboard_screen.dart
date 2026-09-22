// lib/screens/scoreboard_screen.dart
//
// v1 match logger with tournament scoring rules.
// Enter the games in each set, the date, optional notes, save.
// On save we ask PadelScoring.validateMatch(...) whether it's a legal
// best-of-3 before storing anything — the rules live in that file, not here.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/match_repository.dart';
import '../services/padel_scoring.dart';
import '../theme.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  // Each entry is one set: [yourGames, theirGames]. Best of 3 → up to 3 rows.
  final List<List<int>> _sets = [
    [0, 0],
  ];
  DateTime _date = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  // The 3rd set is the deciding super tiebreak, so we cap at 3 rows.
  void _addSet() => setState(() {
    if (_sets.length < 3) _sets.add([0, 0]);
  });

  void _removeSet(int i) => setState(() {
    if (_sets.length > 1) _sets.removeAt(i);
  });

  void _bump(int setIndex, int side, int delta) {
    setState(() {
      final next = _sets[setIndex][side] + delta;
      if (next >= 0 && next <= 99) _sets[setIndex][side] = next;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final sets = _sets
        .map((s) => PadelSet(yourGames: s[0], theirGames: s[1]))
        .toList();

    // Ask the rulebook. null == valid; otherwise it hands back the reason.
    final error = PadelScoring.validateMatch(sets);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.loss),
      );
      return; // stop — nothing is saved
    }

    final match = Match(
      id: const Uuid().v4(),
      date: _date,
      sets: sets,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    context.read<MatchRepository>().addMatch(match);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a match')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Date row
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.courtMid),
                  const SizedBox(width: 10),
                  Text(
                    'Played ${DateFormat('EEE d MMM').format(_date)}',
                    style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  ),
                  const Spacer(),
                  const Text(
                    'Change',
                    style: TextStyle(color: AppColors.courtMid),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),

          for (int i = 0; i < _sets.length; i++) ...[
            _SetRow(
              index: i,
              isDecider: i == 2, // 3rd row = super tiebreak to 10
              you: _sets[i][0],
              them: _sets[i][1],
              onBump: _bump,
              onRemove: _sets.length > 1 ? () => _removeSet(i) : null,
            ),
            const SizedBox(height: 12),
          ],

          // Only offer "add set" while there's room (best of 3).
          if (_sets.length < 3)
            TextButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add),
              label: Text(
                _sets.length == 2 ? 'Add deciding tiebreak' : 'Add set',
              ),
            ),

          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Notes (optional) — e.g. what gave you trouble',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
              ),
            ),
          ),

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
                'Save match',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.isDecider,
    required this.you,
    required this.them,
    required this.onBump,
    required this.onRemove,
  });

  final int index;
  final bool isDecider;
  final int you;
  final int them;
  final void Function(int setIndex, int side, int delta) onBump;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final title = isDecider ? 'Tiebreak' : 'Set ${index + 1}';
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
          Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: _Counter(
                  label: 'You',
                  value: you,
                  onDelta: (d) => onBump(index, 0, d),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Counter(
                  label: 'Them',
                  value: them,
                  onDelta: (d) => onBump(index, 1, d),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  tooltip: 'Remove set',
                ),
            ],
          ),
          if (isDecider)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 2),
              child: Text(
                'Deciding super tiebreak — first to 10, win by 2',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onDelta,
  });
  final String label;
  final int value;
  final void Function(int delta) onDelta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundBtn(icon: Icons.remove, onTap: () => onDelta(-1)),
            SizedBox(
              width: 34,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            _RoundBtn(icon: Icons.add, onTap: () => onDelta(1)),
          ],
        ),
      ],
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
