// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/match_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PadelProgressApp());
}

class PadelProgressApp extends StatelessWidget {
  const PadelProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider makes the one MatchRepository available to every
    // screen below it. `..load()` kicks off reading saved matches from disk.
    return ChangeNotifierProvider(
      create: (_) => MatchRepository()..load(),
      child: MaterialApp(
        title: 'Padel Progress',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
