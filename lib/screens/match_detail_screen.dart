// lib/screens/match_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/models.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final Match match; // the data handed in when we open this screen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Match played on ${match.date}'), // ugly date for now — placeholder
      ),
    );
  }
}