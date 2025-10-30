import 'package:flutter/material.dart';

import 'route.dart';

void main() {
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void secondaryDisplayMain() {
  runApp(const MySecondApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      onGenerateRoute: generateRoute,
      initialRoute: '/',
    );
  }
}

class MySecondApp extends StatelessWidget {
  const MySecondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      onGenerateRoute: generateRoute,
      initialRoute: 'presentation',
    );
  }
}
