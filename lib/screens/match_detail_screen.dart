// lib/screens/match_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/match_repository.dart';
import '../theme.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    // Result -> a word + a colour (same idea as _ResultBadge on the home list).
    final (label, color) = switch (match.didWin) {
      true => ('Win', AppColors.win),
      false => ('Loss', AppColors.loss),
      null => ('Draw', AppColors.inkSoft),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete match',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Result header ---
          Text(
            label,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE d MMMM y').format(match.date),
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
          ),

          const SizedBox(height: 24),

          // --- Set-by-set breakdown ---
          Text('Sets', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (match.sets.isEmpty)
            const Text(
              'No sets recorded.',
              style: TextStyle(color: AppColors.inkSoft),
            )
          else
            // Turn each set (data) into a row (widget).
            for (int i = 0; i < match.sets.length; i++)
              _SetLine(index: i, set: match.sets[i]),

          // --- Notes (only if there are any) ---
          if (match.notes != null && match.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              match.notes!,
              style: const TextStyle(
                color: AppColors.ink,
                height: 1.4,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Ask before deleting, then delete and go back to the home list.
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this match?'),
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
      context.read<MatchRepository>().deleteMatch(match.id);
      Navigator.of(context).pop(); // leave the detail screen
    }
  }
}

// One row in the set breakdown: "Set 1   6 – 4".
class _SetLine extends StatelessWidget {
  const _SetLine({required this.index, required this.set});

  final int index;
  final PadelSet set;

  @override
  Widget build(BuildContext context) {
    final youWon = set.wonByYou;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          children: [
            Text(
              'Set ${index + 1}',
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${set.yourGames} – ${set.theirGames}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: youWon ? AppColors.win : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
