// lib/screens/scoreboard_screen.dart
//
// v1 match logger with tournament scoring rules + players.
// Enter partner/opponents, the games in each set, the date, optional notes.
// On save we validate the score, then turn each typed name into a Contact id
// (reusing an existing contact when the name matches) and store the ids.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/match_repository.dart';
import '../services/contact_repository.dart';
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

  // One controller per player name field.
  final _partner = TextEditingController();
  final _opp1 = TextEditingController();
  final _opp2 = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    _partner.dispose();
    _opp1.dispose();
    _opp2.dispose();
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

  Future<void> _save() async {
    final sets = _sets
        .map((s) => PadelSet(yourGames: s[0], theirGames: s[1]))
        .toList();

    // 1) Validate the score first. null == valid.
    final error = PadelScoring.validateMatch(sets);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.loss),
      );
      return; // stop — nothing is saved
    }

    // Grab the repositories BEFORE any await, so we never use `context`
    // across an async gap (that's the rule the mounted-guard below backs up).
    final contactRepo = context.read<ContactRepository>();
    final matchRepo = context.read<MatchRepository>();

    // 2) Turn each typed name into a Contact id (reuse or create).
    final partnerId = await _resolveName(contactRepo, _partner.text);
    final opp1Id = await _resolveName(contactRepo, _opp1.text);
    final opp2Id = await _resolveName(contactRepo, _opp2.text);

    // 3) Save the match with the linked player ids.
    final match = Match(
      id: const Uuid().v4(),
      date: _date,
      sets: sets,
      partnerId: partnerId,
      opponent1Id: opp1Id,
      opponent2Id: opp2Id,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    await matchRepo.addMatch(match);

    // We awaited above, so this widget could be gone — check before using it.
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Empty name -> null. Otherwise find-or-create the contact and return its id.
  Future<String?> _resolveName(ContactRepository repo, String name) async {
    if (name.trim().isEmpty) return null;
    final contact = await repo.findOrCreate(name);
    return contact.id;
  }

  @override
  Widget build(BuildContext context) {
    // Existing contacts, so the fields can suggest names you've used before.
    final known = context
        .watch<ContactRepository>()
        .contacts
        .map((c) => c.name)
        .toList();

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

          // --- Players ---
          Text('Players', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PlayerField(
            label: 'Your partner',
            controller: _partner,
            suggestions: known,
          ),
          const SizedBox(height: 10),
          _PlayerField(
            label: 'Opponent 1',
            controller: _opp1,
            suggestions: known,
          ),
          const SizedBox(height: 10),
          _PlayerField(
            label: 'Opponent 2',
            controller: _opp2,
            suggestions: known,
          ),

          const SizedBox(height: 20),
          Text('Score', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

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

// A labeled name field that suggests contacts you've already used.
// Built on Flutter's Autocomplete: you can pick a suggestion or just type
// a new name — either way the text ends up in `controller`.
class _PlayerField extends StatelessWidget {
  const _PlayerField({
    required this.label,
    required this.controller,
    required this.suggestions,
  });

  final String label;
  final TextEditingController controller;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      // Which known names match what's been typed so far.
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        final q = value.text.toLowerCase();
        return suggestions.where((n) => n.toLowerCase().contains(q));
      },
      // Keep our own controller in sync with what the user types/picks.
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        // Mirror edits back into the controller _save reads.
        textController.text = controller.text;
        textController.addListener(() => controller.text = textController.text);
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
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
        );
      },
      onSelected: (selection) => controller.text = selection,
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
