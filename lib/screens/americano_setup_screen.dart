// lib/screens/americano_setup_screen.dart
//
// Step 1 of an Americano session: enter the 4 player names, then Start.
// StatefulWidget because it manages 4 TextEditingControllers (state to dispose).

import 'package:flutter/material.dart';
import '../theme.dart';
import 'americano_session_screen.dart';

class AmericanoSetupScreen extends StatefulWidget {
  const AmericanoSetupScreen({super.key});

  @override
  State<AmericanoSetupScreen> createState() => _AmericanoSetupScreenState();
}

class _AmericanoSetupScreenState extends State<AmericanoSetupScreen> {
  // One controller per name field (a list of 4).
  final _controllers = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final names = _controllers.map((c) => c.text.trim()).toList();
    if (names.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill in all 4 names')));
      return;
    }
    // Replace this screen with the scoring screen, so "back" returns to the
    // list, not here.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AmericanoSessionScreen(players: names)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter the 4 players:',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _controllers.length; i++) ...[
            TextField(
              controller: _controllers[i],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Player ${i + 1}',
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
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.court,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Start',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
