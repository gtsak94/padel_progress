// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/match_repository.dart';
import 'services/contact_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PadelProgressApp());
}

class PadelProgressApp extends StatelessWidget {
  const PadelProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We now have TWO repositories to share with the app, so we swap the single
    // ChangeNotifierProvider for a MultiProvider that holds both. Every screen
    // below can read/watch either one, exactly as before.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchRepository()..load()),
        ChangeNotifierProvider(create: (_) => ContactRepository()..load()),
      ],
      child: MaterialApp(
        title: 'Padel Progress',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
