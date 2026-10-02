// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/match_repository.dart';
import 'services/contact_repository.dart';
import 'services/americano_repository.dart';
import 'screens/main_scaffold.dart';

void main() {
  runApp(const PadelProgressApp());
}

class PadelProgressApp extends StatelessWidget {
  const PadelProgressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchRepository()..load()),
        ChangeNotifierProvider(create: (_) => ContactRepository()..load()),
        ChangeNotifierProvider(create: (_) => AmericanoRepository()..load()),
      ],
      child: MaterialApp(
        title: 'Padel Progress',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const MainScaffold(),
      ),
    );
  }
}
