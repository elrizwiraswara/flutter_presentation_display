import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'presentation_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const MainScreen());
    case 'presentation':
      return MaterialPageRoute(builder: (_) => const PresentationScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
